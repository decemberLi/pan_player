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
    let fileId: String?
    let parentId: String?
    let fileName: String?
    let fileSize: String?
    let fileSha1: String?
    let fileType: String?
    let isPrivate: String?
    let playLong: String?
    let userDef: Int?
    let userRotate: Int?
    let userTurn: Int?
    let multiTrackList: [MultiTrackList115]?
    let definitionList: [String: String]?
    let definitionListNew: [String: String]?
    let videoUrl: [VideoURL115]?
    
    enum CodingKeys: String, CodingKey {
        case fileId = "file_id"
        case parentId = "parent_id"
        case fileName = "file_name"
        case fileSize = "file_size"
        case fileSha1 = "file_sha1"
        case fileType = "file_type"
        case isPrivate = "is_private"
        case playLong = "play_long"
        case userDef = "user_def"
        case userRotate = "user_rotate"
        case userTurn = "user_turn"
        case multiTrackList = "multitrack_list"
        case definitionList = "definition_list"
        case definitionListNew = "definition_list_new"
        case videoUrl = "video_url"
    }
}

// MARK: - DefinitionListNew115
// This struct is no longer needed as we're using a dictionary [String: String] instead
// struct DefinitionListNew115: Codable {
//     let title, isSelected: String
// }

// MARK: - VideoURL115
struct VideoURL115: Codable {
    let url: String
    let height, width, definition: Int
    let title: String
    let definitionN: Int
    
    enum CodingKeys: String, CodingKey {
        case url
        case height
        case width
        case definition
        case title
        case definitionN = "definition_n"
    }
}

struct MultiTrackList115: Codable {
    let title: String?
    let isSelected: Bool?

    enum CodingKeys: String, CodingKey {
        case title
        case isSelected = "is_selected"
    }
}
