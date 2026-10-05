import Foundation

public enum TransactionClassification {
    case debit(Decimal)
    case credit(Decimal)
    case unclassified
}

public enum SecurityStatementParserError: Error {
    case invalidFormat
    case missingStatementNumber
}

public final class SecurityStatementParserV2 {
    private let dateFormatter = DateFormatter()

    public init() {
        dateFormatter.locale = Locale(identifier: "es_CL")
        dateFormatter.dateFormat = "dd/MM"
    }

    public func parse(_ text: String, sourceFileName: String) throws -> ParsedStatement {
        let lines = normalize(text).split(whereSeparator: { $0.isNewline }).map(String.init)
        guard !lines.isEmpty else { throw SecurityStatementParserError.invalidFormat }

        let issueDate = extractIssueDate(from: lines) ?? Date()
        let statementNumber = extractStatementNumber(from: lines) ?? "SEC-UNKNOWN"
        let periodStart = extractPeriodStart(from: lines) ?? issueDate
        let periodEnd = extractPeriodEnd(from: lines) ?? issueDate
        let openingBalance = extractOpeningBalance(from: lines) ?? Decimal.zero

        var transactions: [ParsedTransaction] = []
        var warnings: [String] = []
        var runningBalance = openingBalance

        for line in lines {
            if line.lowercased().contains("total") || line.lowercased().contains("saldo") {
                continue
            }

            guard let parsed = parseSecurityLine(line, previousBalance: runningBalance) else { continue }

            let confidence = validateBalance(previousBalance: runningBalance, delta: parsed.amount, result: parsed.resultingBalance)
            let requiresReview = confidence < 0.95
            if requiresReview { warnings.append(line) }

            let fingerprint = FinancialHashing.transactionFingerprint(
                documentNumber: parsed.documentNumber,
                date: parsed.date,
                description: parsed.description,
                amount: parsed.amount
            )

            let effectiveDebit: Decimal?
            let effectiveCredit: Decimal?

            if parsed.classification == .debit {
                effectiveDebit = parsed.amount
                effectiveCredit = nil
            } else if parsed.classification == .credit {
                effectiveDebit = nil
                effectiveCredit = parsed.amount
            } else {
                effectiveDebit = nil
                effectiveCredit = nil
            }

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

    private func parseSecurityLine(_ line: String, previousBalance: Decimal) -> (date: Date, documentNumber: String, description: String, amount: Decimal, classification: TransactionClassification, resultingBalance: Decimal)? {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let tokens = trimmed.split(whereSeparator: { $0.isWhitespace }).map(String.init)
        guard tokens.count >= 4 else { return nil }

        let documentNumber = tokens[0]
        guard isValidDocumentNumber(documentNumber) else { return nil }

        guard let dateToken = tokens.first(where: { isDateToken($0) }) else { return nil }
        guard let date = parseDate(dateToken) else { return nil }
        guard let dateIndex = tokens.firstIndex(of: dateToken) else { return nil }

        let beforeDate = Array(tokens[0..<dateIndex])
        let afterDate = Array(tokens[(dateIndex + 1)...])

        let amount = extractAmount(from: beforeDate + afterDate) ?? Decimal.zero
        guard amount > 0 else { return nil }

        let resultingBalance = extractBalance(from: tokens) ?? previousBalance
        let delta = resultingBalance - previousBalance

        let classification: TransactionClassification
        if abs(delta + amount) < 0.01 {
            classification = .debit(amount)
        } else if abs(delta - amount) < 0.01 {
            classification = .credit(amount)
        } else {
            classification = .unclassified
        }

        let descriptionTokens = beforeDate.filter { $0 != documentNumber } + afterDate.filter { !isNumericToken($0) }
        let description = descriptionTokens.joined(separator: " ")
        guard !description.isEmpty else { return nil }

        return (date, documentNumber, description, amount, classification, resultingBalance)
    }

    private func validateBalance(previousBalance: Decimal, delta: Decimal, result: Decimal) -> Double {
        let expected1 = previousBalance - delta
        let expected2 = previousBalance + delta

        if abs(expected1 - result) < 0.01 || abs(expected2 - result) < 0.01 {
            return 0.98
        }
        return 0.72
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
            if line.lowercased().contains("desde") || line.lowercased().contains("periodo") {
                if let date = extractDates(in: line).first { return date }
            }
        }
        return nil
    }

    private func extractPeriodEnd(from lines: [String]) -> Date? {
        for line in lines {
            if line.lowercased().contains("hasta") {
                if let date = extractDates(in: line).last { return date }
            }
        }
        return nil
    }

    private func extractOpeningBalance(from lines: [String]) -> Decimal? {
        for line in lines {
            if line.lowercased().contains("saldo inicial") || line.lowercased().contains("saldoinicial") {
                return extractAmount(from: line)
            }
        }
        return Decimal.zero
    }

    private func extractDates(in text: String) -> [Date] {
        let pattern = "\\b(\\d{2})/(\\d{2})(?:/(\\d{4}))?\\b"
        let regex = try? NSRegularExpression(pattern: pattern)
        guard let matches = regex?.matches(in: text, range: NSRange(text.startIndex..., in: text)) else { return [] }

        var results: [Date] = []
        for match in matches {
            let raw = (text as NSString).substring(with: match.range)
            if let date = parseDate(raw) { results.append(date) }
        }
        return results
    }

    private func extractAmount(from text: String) -> Decimal? {
        let pattern = "\\d{1,3}(?:\\.\\d{3})*(?:,\\d+)?"
        let regex = try? NSRegularExpression(pattern: pattern)
        guard let matches = regex?.matches(in: text, range: NSRange(text.startIndex..., in: text)) else { return nil }

        for match in matches.reversed() {
            let raw = (text as NSString).substring(with: match.range)
            let sanitized = raw.replacingOccurrences(of: ".", with: "").replacingOccurrences(of: ",", with: ".")
            if let value = Decimal(string: sanitized), value > 0 { return value }
        }
        return nil
    }

    private func extractBalance(from tokens: [String]) -> Decimal? {
        let text = tokens.joined(separator: " ")
        let pattern = "\\d{1,3}(?:\\.\\d{3})*(?:,\\d+)?"
        let regex = try? NSRegularExpression(pattern: pattern)
        guard let matches = regex?.matches(in: text, range: NSRange(text.startIndex..., in: text)) else { return nil }

        for match in matches.reversed() {
            let raw = (text as NSString).substring(with: match.range)
            let sanitized = raw.replacingOccurrences(of: ".", with: "").replacingOccurrences(of: ",", with: ".")
            if let value = Decimal(string: sanitized) { return value }
        }
        return nil
    }

    private func isDateToken(_ token: String) -> Bool {
        token.range(of: "^\\d{2}/\\d{2}$", options: .regularExpression) != nil
    }

    private func isNumericToken(_ token: String) -> Bool {
        let sanitized = token.replacingOccurrences(of: ".", with: "").replacingOccurrences(of: ",", with: ".")
        return Decimal(string: sanitized) != nil
    }

    private func isValidDocumentNumber(_ token: String) -> Bool {
        token.range(of: "^\\d{7,10}$", options: .regularExpression) != nil
    }

    private func parseDate(_ raw: String) -> Date? {
        dateFormatter.date(from: raw.count == 5 ? raw : String(raw.prefix(5)))
    }
}
