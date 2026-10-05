import Foundation
import CryptoKit

public enum FinancialHashing {
    public static func sha256(_ value: String) -> String {
        let data = Data(value.utf8)
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    public static func statementFingerprint(fileName: String, issueDate: Date, statementNumber: String) -> String {
        let payload = [fileName, statementNumber, String(issueDate.timeIntervalSince1970)].joined(separator: "|")
        return sha256(payload)
    }

    public static func transactionFingerprint(documentNumber: String, date: Date, description: String, amount: Decimal) -> String {
        let payload = [documentNumber, description, String(date.timeIntervalSince1970), NSDecimalNumber(decimal: amount).stringValue].joined(separator: "|")
        return sha256(payload)
    }
}
