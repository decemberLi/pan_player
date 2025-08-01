import Foundation

// MARK: - VideoData115
struct VideoData115: Codable {
    let state: Bool
    let message: String?
    let code: Int
    let data: DataClass115?
}

// MARK: - DataClass115
struct DataClass115: Codable {
    let fileId, parentId, fileName, fileSize: String
    let fileSha1, fileType, isPrivate, playLong: String
    let userDef, userRotate, userTurn: Int
    let multitrackList: [MultitrackList115]
    let definitionListNew: [DefinitionListNew115]
    let videoUrl: [VideoURL115]
}

// MARK: - DefinitionListNew115
struct DefinitionListNew115: Codable {
    let title, isSelected: String
}

// MARK: - MultitrackList115
struct MultitrackList115: Codable {
    let title, isSelected: String
}

// MARK: - VideoURL115
struct VideoURL115: Codable {
    let url: String
    let height, width, definition, title: Int
    let definitionN: Int
}