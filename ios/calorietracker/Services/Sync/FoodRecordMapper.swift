import Foundation
import CloudKit

/// Maps FoodEntry ↔ CKRecord (used for both logged entries and favorites).
/// Photos travel as CKAsset; decode writes the bytes back to FoodImageStore.
enum FoodRecordMapper {

    static func record(from entry: FoodEntry, kind: SyncRecordKind, zoneID: CKRecordZone.ID) -> CKRecord {
        let recordID = CKRecord.ID(recordName: kind.recordName(for: entry.id), zoneID: zoneID)
        let record = CKRecord(recordType: kind.recordType, recordID: recordID)
        record["entryID"] = entry.id.uuidString
        record["name"] = entry.name
        record["calories"] = entry.calories
        record["protein"] = entry.protein
        record["carbs"] = entry.carbs
        record["fat"] = entry.fat
        record["timestamp"] = entry.timestamp
        record["emoji"] = entry.emoji
        record["source"] = entry.source.rawValue
        record["mealType"] = entry.mealType.rawValue
        record["modifiedAt"] = entry.modifiedAt
        let optionals: [String: Double?] = [
            "sugar": entry.sugar, "addedSugar": entry.addedSugar, "fiber": entry.fiber,
            "saturatedFat": entry.saturatedFat, "monounsaturatedFat": entry.monounsaturatedFat,
            "polyunsaturatedFat": entry.polyunsaturatedFat, "cholesterol": entry.cholesterol,
            "sodium": entry.sodium, "potassium": entry.potassium, "servingSizeGrams": entry.servingSizeGrams,
        ]
        for (key, value) in optionals {
            if let value { record[key] = value }
        }
        if let filename = entry.imageFilename,
           let storeURL = FoodImageStore.shared.fileURL(for: filename),
           FileManager.default.fileExists(atPath: storeURL.path) {
            record["photoFilename"] = filename
            record["photo"] = CKAsset(fileURL: storeURL)
        }
        // Note: servingUnitOptions/selectedServingUnit/selectedServingQuantity are device-local presentation hints, not synced.
        return record
    }

    static func foodEntry(from record: CKRecord) -> FoodEntry? {
        guard let idString = record["entryID"] as? String, let id = UUID(uuidString: idString),
              let name = record["name"] as? String,
              let calories = record["calories"] as? Int,
              let protein = record["protein"] as? Int,
              let carbs = record["carbs"] as? Int,
              let fat = record["fat"] as? Int,
              let timestamp = record["timestamp"] as? Date,
              let sourceRaw = record["source"] as? String,
              let source = FoodSource(rawValue: sourceRaw)
        else { return nil }

        // Materialize the photo back to local disk under its logical filename.
        // Keep the filename regardless; write bytes back only if the asset is present.
        let imageFilename = record["photoFilename"] as? String
        if imageFilename != nil, let asset = record["photo"] as? CKAsset, let url = asset.fileURL,
           let data = try? Data(contentsOf: url) {
            _ = FoodImageStore.shared.store(data: data, for: id)
        }

        let mealType = MealType(rawValue: record["mealType"] as? String ?? "") ?? .other
        return FoodEntry(
            id: id, name: name, calories: calories, protein: protein, carbs: carbs, fat: fat,
            timestamp: timestamp, imageData: nil, imageFilename: imageFilename,
            emoji: record["emoji"] as? String, source: source, mealType: mealType,
            sugar: record["sugar"] as? Double, addedSugar: record["addedSugar"] as? Double,
            fiber: record["fiber"] as? Double, saturatedFat: record["saturatedFat"] as? Double,
            monounsaturatedFat: record["monounsaturatedFat"] as? Double,
            polyunsaturatedFat: record["polyunsaturatedFat"] as? Double,
            cholesterol: record["cholesterol"] as? Double, sodium: record["sodium"] as? Double,
            potassium: record["potassium"] as? Double, servingSizeGrams: record["servingSizeGrams"] as? Double,
            modifiedAt: record["modifiedAt"] as? Date
        )
    }
}
