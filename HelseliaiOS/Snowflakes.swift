import Foundation

func getCurrentTimeStampWOMiliseconds(dateToConvert: NSDate) -> String {
    let objDateformat: DateFormatter = DateFormatter()
    objDateformat.dateFormat = "yyyy-MM-dd"
    let strTime: String = objDateformat.string(from: dateToConvert as Date)
    let objUTCDate: NSDate = objDateformat.date(from: strTime)! as NSDate
    let milliseconds: Int64 = Int64(objUTCDate.timeIntervalSince1970)
    let strTimeStamp: String = "\(milliseconds)"
    return strTimeStamp
}

func generateSnowflakes(userID: Int, channelID: Int, messageID: Int) -> String {
    let date = NSDate()
    let nowTimeStamp: Int = Int(getCurrentTimeStampWOMiliseconds(dateToConvert: date)) ?? 0
    let messageIdentification = "\(messageID)\(userID)\(channelID)"
    let returnedSnowflake = "\(nowTimeStamp)\(messageIdentification)"
    return returnedSnowflake
}

enum outputTypes {
    case userID
    case messageID
    case timestamp
    case channelID
}

func parseSnowflakes(output: outputTypes, snowflake: String) -> String {
    switch output {
    case .timestamp:
        return String(snowflake.prefix(snowflake.count - 36))
    case .userID:
        return String(String(snowflake.suffix(24)).prefix(12))
    case .messageID:
        return String(String(snowflake.suffix(36).prefix(12)))
    case .channelID:
        return String(snowflake.suffix(12))
    }
}
