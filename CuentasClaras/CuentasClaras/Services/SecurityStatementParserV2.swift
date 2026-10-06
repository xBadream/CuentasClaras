import Foundation

public enum TransactionClassification: Equatable {
    case debit
    case credit
    case unclassified
}

public enum SecurityStatementParserError: Error {
    case invalidFormat
    case missingStatementNumber
}

public final class SecurityStatementParserV2 {
    private let dateFormatter = DateFormatter()

    private struct ParsedLine {
        let date: Date
        let documentNumber: String
        let description: String
        let amount: Decimal
        let classification: TransactionClassification
        let resultingBalance: Decimal
        let inferred: Bool
    }

    public init() {
        dateFormatter.locale = Locale(identifier: "es_CL")
        dateFormatter.dateFormat = "dd/MM"
    }

    public func parse(_ text: String, sourceFileName: String) throws -> ParsedStatement {
        var lines = normalize(text).split(whereSeparator: { $0.isNewline }).map(String.init)
        guard !lines.isEmpty else { throw SecurityStatementParserError.invalidFormat }

        let issueDate = extractIssueDate(from: lines) ?? Date()
        let statementNumber = extractStatementNumber(from: lines) ?? "SEC-UNKNOWN"
        let periodStart = extractPeriodStart(from: lines) ?? issueDate
        let periodEnd = extractPeriodEnd(from: lines) ?? issueDate
        let declaredOpening = extractOpeningBalance(from: lines)

        // Algunas cartolas listan los movimientos del más nuevo al más antiguo: ordenarlos cronológicamente.
        let txIndices = lines.indices.filter { index in
            let tokens = lines[index].split(whereSeparator: { $0.isWhitespace }).map(String.init)
            return tokens.first.map(isValidDocumentNumber) == true && tokens.contains(where: isDateToken)
        }
        let txDates: [Date] = txIndices.compactMap { index in
            lines[index].split(whereSeparator: { $0.isWhitespace }).map(String.init)
                .first(where: isDateToken).flatMap(parseDate)
        }
        if let first = txDates.first, let last = txDates.last, first > last {
            lines.reverse()
        }

        var openingBalance = declaredOpening ?? Decimal.zero
        var transactions: [ParsedTransaction] = []
        var warnings: [String] = []
        var runningBalance = openingBalance
        var needsOpening = declaredOpening == nil

        for line in lines {
            let lower = line.lowercased()
            let firstToken = line.split(whereSeparator: { $0.isWhitespace }).first.map(String.init) ?? ""
            if (lower.contains("total") || lower.contains("saldo")) && !isValidDocumentNumber(firstToken) {
                continue
            }

            guard let parsed = parseSecurityLine(line, previousBalance: needsOpening ? nil : runningBalance) else { continue }

            if needsOpening {
                openingBalance = parsed.classification == .credit
                    ? parsed.resultingBalance - parsed.amount
                    : parsed.resultingBalance + parsed.amount
                needsOpening = false
            }

            let confidence: Double = parsed.inferred ? 0.72 : 0.98
            let requiresReview = confidence < 0.95
            if requiresReview { warnings.append(line) }

            let fingerprint = FinancialHashing.transactionFingerprint(
                documentNumber: parsed.documentNumber,
                date: parsed.date,
                description: parsed.description,
                amount: parsed.amount
            )

            let effectiveDebit: Decimal? = parsed.classification == .debit ? parsed.amount : nil
            let effectiveCredit: Decimal? = parsed.classification == .credit ? parsed.amount : nil

            transactions.append(ParsedTransaction(
                date: parsed.date,
                documentNumber: parsed.documentNumber,
                transactionDescription: parsed.description,
                debitAmount: effectiveDebit,
                creditAmount: effectiveCredit,
                resultingBalance: parsed.resultingBalance,
                parserConfidence: confidence,
                sourcePage: 1,
                sourceRawText: line,
                categoryName: nil,
                requiresReview: requiresReview,
                importFingerprint: fingerprint
            ))

            runningBalance = parsed.resultingBalance
        }

        let totalDebits = transactions.compactMap { $0.debitAmount }.reduce(Decimal.zero, +)
        let totalCredits = transactions.compactMap { $0.creditAmount }.reduce(Decimal.zero, +)
        let accountingBalance = openingBalance + totalCredits - totalDebits

        let fingerprint = FinancialHashing.statementFingerprint(
            fileName: sourceFileName,
            issueDate: issueDate,
            statementNumber: statementNumber
        )

        return ParsedStatement(
            statementNumber: statementNumber,
            periodStart: periodStart,
            periodEnd: periodEnd,
            issueDate: issueDate,
            sourceFileName: sourceFileName,
            openingBalance: openingBalance,
            totalDebits: totalDebits,
            totalCredits: totalCredits,
            accountingBalance: accountingBalance,
            availableBalance: accountingBalance,
            totalFees: Decimal.zero,
            transactions: transactions,
            warnings: warnings,
            importFingerprint: fingerprint
        )
    }

    // Formato esperado: <documento> [monto] <descripción> <dd/MM> [monto] <saldo>
    private func parseSecurityLine(_ line: String, previousBalance: Decimal?) -> ParsedLine? {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let tokens = trimmed.replacingOccurrences(of: "$", with: " ")
            .split(whereSeparator: { $0.isWhitespace }).map(String.init)
        guard tokens.count >= 4 else { return nil }

        let documentNumber = tokens[0]
        guard isValidDocumentNumber(documentNumber) else { return nil }

        guard let dateIndex = tokens.firstIndex(where: { isDateToken($0) }) else { return nil }
        guard let date = parseDate(tokens[dateIndex]) else { return nil }

        var numericValues: [Decimal] = []
        var descriptionTokens: [String] = []
        for (index, token) in tokens.enumerated() {
            if index == 0 || index == dateIndex { continue }
            if let value = parseDecimal(token) {
                numericValues.append(value)
            } else {
                descriptionTokens.append(token)
            }
        }

        // El último número es el saldo; el anterior es el monto de la operación.
        guard numericValues.count >= 2,
              let resultingBalance = numericValues.last else { return nil }
        let amount = numericValues[numericValues.count - 2]
        guard amount > 0 else { return nil }

        let classification: TransactionClassification
        if let previousBalance = previousBalance {
            let delta = resultingBalance - previousBalance
            if abs(NSDecimalNumber(decimal: delta + amount).doubleValue) < 0.01 {
                classification = .debit
            } else if abs(NSDecimalNumber(decimal: delta - amount).doubleValue) < 0.01 {
                classification = .credit
            } else {
                classification = .unclassified
            }
        } else {
            classification = .unclassified
        }

        let description = descriptionTokens.joined(separator: " ")
        guard !description.isEmpty else { return nil }

        // Si el saldo previo es desconocido, inferir por la descripción para no dejar montos en 0.
        let finalClassification: TransactionClassification
        if classification == .unclassified {
            let upper = description.uppercased()
            let creditHints = ["ABONO", "DEPOSITO", "DEPÓSITO", "DESDE", "SUELDO", "REMUNERACION", "REMUNERACIÓN", "INTERES GANADO", "INTERÉS GANADO"]
            finalClassification = creditHints.contains(where: { upper.contains($0) }) ? .credit : .debit
        } else {
            finalClassification = classification
        }

        return ParsedLine(
            date: date,
            documentNumber: documentNumber,
            description: description,
            amount: amount,
            classification: finalClassification,
            resultingBalance: resultingBalance,
            inferred: classification == .unclassified
        )
    }

    private func normalize(_ text: String) -> String {
        text
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
    }

    private func extractStatementNumber(from lines: [String]) -> String? {
        for line in lines {
            let lower = line.lowercased()
            if lower.contains("cartola") || lower.contains("cuenta") {
                return line.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        return nil
    }

    private func extractIssueDate(from lines: [String]) -> Date? {
        for line in lines {
            if let date = extractDates(in: line).first { return date }
        }
        return nil
    }

    private func extractPeriodStart(from lines: [String]) -> Date? {
        for line in lines {
            let lower = line.lowercased()
            if lower.contains("desde") || lower.contains("periodo") {
                if let date = extractDates(in: line).first { return date }
            }
        }
        return nil
    }

    private func extractPeriodEnd(from lines: [String]) -> Date? {
        for line in lines {
            let lower = line.lowercased()
            if lower.contains("hasta") || lower.contains("periodo") {
                if let date = extractDates(in: line).last { return date }
            }
        }
        return nil
    }

    private func extractOpeningBalance(from lines: [String]) -> Decimal? {
        for line in lines {
            let lower = line.lowercased()
            if lower.contains("saldo inicial") || lower.contains("saldoinicial") {
                return extractAmount(from: line)
            }
        }
        return nil
    }

    private func extractDates(in text: String) -> [Date] {
        let pattern = "\\b(\\d{2})/(\\d{2})(?:/(\\d{4}))?\\b"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))

        var results: [Date] = []
        for match in matches {
            let raw = (text as NSString).substring(with: match.range)
            if let date = parseDate(raw) { results.append(date) }
        }
        return results
    }

    private func extractAmount(from text: String) -> Decimal? {
        let pattern = "\\d{1,3}(?:\\.\\d{3})*(?:,\\d+)?"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))

        for match in matches.reversed() {
            let raw = (text as NSString).substring(with: match.range)
            if let value = parseDecimal(raw), value > 0 { return value }
        }
        return nil
    }

    private func parseDecimal(_ token: String) -> Decimal? {
        // Solo números con formato chileno: 1.234.567 o 1.234,56
        guard token.range(of: "^\\d{1,3}(\\.\\d{3})*(,\\d+)?$|^\\d+(,\\d+)?$", options: .regularExpression) != nil else {
            return nil
        }
        let sanitized = token.replacingOccurrences(of: ".", with: "").replacingOccurrences(of: ",", with: ".")
        return Decimal(string: sanitized, locale: Locale(identifier: "en_US_POSIX"))
    }

    private func isDateToken(_ token: String) -> Bool {
        token.range(of: "^\\d{2}/\\d{2}$", options: .regularExpression) != nil
    }

    private func isValidDocumentNumber(_ token: String) -> Bool {
        token.range(of: "^\\d{7,10}$", options: .regularExpression) != nil
    }

    private func parseDate(_ raw: String) -> Date? {
        dateFormatter.date(from: String(raw.prefix(5)))
    }
}
