import Foundation
import UIKit

final class InsurancePDFService {
    static let shared = InsurancePDFService()

    private let pageWidth: CGFloat = 612 // US Letter
    private let pageHeight: CGFloat = 792
    private let margin: CGFloat = 50

    func generateSummary(watches: [Watch]) async -> URL? {
        let contentWidth = pageWidth - margin * 2

        let format = UIGraphicsPDFRendererFormat()
        let renderer = UIGraphicsPDFRenderer(
            bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight),
            format: format
        )

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long

        let currencyFormatter = NumberFormatter()
        currencyFormatter.numberStyle = .currency
        currencyFormatter.currencyCode = "USD"

        let data = renderer.pdfData { context in
            var yPos: CGFloat = 0

            func newPage() {
                context.beginPage()
                yPos = margin
            }

            func checkPageBreak(_ needed: CGFloat) {
                if yPos + needed > pageHeight - margin {
                    newPage()
                }
            }

            func drawText(_ text: String, at y: CGFloat, font: UIFont, color: UIColor = .black, maxWidth: CGFloat? = nil) -> CGFloat {
                let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
                let w = maxWidth ?? contentWidth
                let rect = CGRect(x: margin, y: y, width: w, height: .greatestFiniteMagnitude)
                let boundingRect = (text as NSString).boundingRect(with: CGSize(width: w, height: .greatestFiniteMagnitude), options: [.usesLineFragmentOrigin], attributes: attrs, context: nil)
                (text as NSString).draw(in: CGRect(x: margin, y: y, width: w, height: boundingRect.height), withAttributes: attrs)
                return boundingRect.height
            }

            func drawLine(at y: CGFloat) {
                let path = UIBezierPath()
                path.move(to: CGPoint(x: margin, y: y))
                path.addLine(to: CGPoint(x: pageWidth - margin, y: y))
                UIColor.lightGray.setStroke()
                path.lineWidth = 0.5
                path.stroke()
            }

            // --- Title Page ---
            newPage()

            let titleFont = UIFont.systemFont(ofSize: 24, weight: .bold)
            let h = drawText("Vault Collection Insurance Summary", at: yPos, font: titleFont)
            yPos += h + 8

            let subtitleFont = UIFont.systemFont(ofSize: 12, weight: .regular)
            let dateStr = "Generated: \(dateFormatter.string(from: Date()))"
            let h2 = drawText(dateStr, at: yPos, font: subtitleFont, color: .darkGray)
            yPos += h2 + 4

            let countStr = "\(watches.count) watches in collection"
            let h3 = drawText(countStr, at: yPos, font: subtitleFont, color: .darkGray)
            yPos += h3 + 20

            drawLine(at: yPos)
            yPos += 20

            // --- Per Watch ---
            let headerFont = UIFont.systemFont(ofSize: 16, weight: .semibold)
            let bodyFont = UIFont.systemFont(ofSize: 11, weight: .regular)
            let labelFont = UIFont.systemFont(ofSize: 11, weight: .medium)
            let thumbSize: CGFloat = 80

            for watch in watches {
                checkPageBreak(200)

                // Watch header
                let nameStr = "\(watch.brand) \(watch.modelName)"
                let nh = drawText(nameStr, at: yPos, font: headerFont)
                yPos += nh + 8

                // Photo thumbnail (if available)
                var textX = margin
                if let firstPhoto = watch.photoFileNames.first {
                    if let photo = loadPhotoSync(named: firstPhoto) {
                        let thumbRect = CGRect(x: margin, y: yPos, width: thumbSize, height: thumbSize)
                        photo.draw(in: thumbRect)
                        textX = margin + thumbSize + 12
                    }
                }

                let detailX = textX
                var detailY = yPos

                func drawDetail(_ label: String, _ value: String) {
                    let labelW: CGFloat = 120
                    let labelAttrs: [NSAttributedString.Key: Any] = [.font: labelFont, .foregroundColor: UIColor.darkGray]
                    let valueAttrs: [NSAttributedString.Key: Any] = [.font: bodyFont, .foregroundColor: UIColor.black]

                    (label as NSString).draw(at: CGPoint(x: detailX, y: detailY), withAttributes: labelAttrs)
                    (value as NSString).draw(at: CGPoint(x: detailX + labelW, y: detailY), withAttributes: valueAttrs)
                    detailY += 16
                }

                if let ref = watch.referenceNumber, !ref.isEmpty {
                    drawDetail("Reference:", ref)
                }
                if let serial = watch.serialNumber, !serial.isEmpty {
                    drawDetail("Serial Number:", serial)
                }
                drawDetail("Movement:", watch.movementType.displayName)
                drawDetail("Case:", "\(watch.caseMaterial.displayName)\(watch.caseSize.map { " • \(Int($0))mm" } ?? "")")

                if let purchaseDate = watch.purchaseDate {
                    drawDetail("Purchase Date:", dateFormatter.string(from: purchaseDate))
                }
                if let purchasePrice = watch.purchasePrice {
                    drawDetail("Purchase Price:", currencyFormatter.string(from: NSNumber(value: purchasePrice)) ?? "")
                }
                if let currentValue = watch.currentValue {
                    drawDetail("Est. Current Value:", currencyFormatter.string(from: NSNumber(value: currentValue)) ?? "")
                }

                // Appraisal info
                let appraisals = watch.insuranceDocuments.filter { $0.documentType == .appraisal }
                if !appraisals.isEmpty {
                    let latest = appraisals.sorted { ($0.date ?? .distantPast) > ($1.date ?? .distantPast) }.first!
                    var appraisalStr = "Yes"
                    if let date = latest.date {
                        appraisalStr += " (\(dateFormatter.string(from: date)))"
                    }
                    drawDetail("Appraisal:", appraisalStr)
                }

                // Documents list
                if !watch.insuranceDocuments.isEmpty {
                    let docStr = watch.insuranceDocuments.map(\.documentType.displayName).joined(separator: ", ")
                    drawDetail("Documents:", docStr)
                }

                yPos = max(yPos + thumbSize + 8, detailY + 8)

                drawLine(at: yPos)
                yPos += 16
            }

            // --- Total ---
            checkPageBreak(60)
            yPos += 8
            let totalValue = watches.compactMap(\.currentValue).reduce(0, +)
            let totalPurchase = watches.compactMap(\.purchasePrice).reduce(0, +)

            let totalFont = UIFont.systemFont(ofSize: 14, weight: .bold)
            if totalPurchase > 0 {
                let tph = drawText("Total Purchase Value: \(currencyFormatter.string(from: NSNumber(value: totalPurchase)) ?? "")", at: yPos, font: bodyFont)
                yPos += tph + 4
            }
            let tvh = drawText("Total Estimated Insured Value: \(currencyFormatter.string(from: NSNumber(value: totalValue)) ?? "")", at: yPos, font: totalFont)
            yPos += tvh + 20

            // Footer
            let footerFont = UIFont.systemFont(ofSize: 9, weight: .regular)
            let _ = drawText("This document was generated by Vault for insurance reference purposes. Values are estimates unless supported by a formal appraisal.", at: yPos, font: footerFont, color: .gray)
        }

        // Save to temp file
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("Vault_Insurance_Summary_\(dateFormatter.string(from: Date()).replacingOccurrences(of: " ", with: "_")).pdf")
        do {
            try data.write(to: tempURL)
            return tempURL
        } catch {
            return nil
        }
    }

    private func loadPhotoSync(named fileName: String) -> UIImage? {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let url = docs.appendingPathComponent("WatchPhotos", isDirectory: true).appendingPathComponent(fileName)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }
}
