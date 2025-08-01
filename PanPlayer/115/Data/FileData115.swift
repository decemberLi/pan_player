import Foundation

// MARK: - FileData115
struct FileData115: Codable {
    let data: [FileItem]?
    let count, sysCount, offset, limit: Int?
    let aid: String?
    let cid, isAsc, minSize, maxSize: Int?
    let sysDir, hideData, recordOpenTime: String?
    let star, type: Int?
    let suffix: String?
    let path: [PathItem]?
    let cur, stdir: Int?
    let fields, order: String?
    let state: Bool?
    let code, message: Int?

    enum CodingKeys: String, CodingKey {
        case data, count
        case sysCount = "sys_count"
        case offset, limit, aid, cid
        case isAsc = "is_asc"
        case minSize = "min_size"
        case maxSize = "max_size"
        case sysDir = "sys_dir"
        case hideData = "hide_data"
        case recordOpenTime = "record_open_time"
        case star, type, suffix, path, cur, stdir, fields, order, state, code, message
    }
}

// MARK: - FileItem
struct FileItem: Codable {
    let fid, aid, pid, fc: String?
    let fn, fco, ism: String?
    let isp: Int?
    let pc: String?
    let upt, uet, uppt, cm: Int?
    let fdesc: String?
    let ispl: Int?
    let fl: [FLItem]?
    let sha1: String?
    let fs: Int?
    let fta, ico, fatr: String?
    let isv, def, def2: Int?
    let playLong: Int?
    let vImg, thumb, uo: String?

    enum CodingKeys: String, CodingKey {
        case fid, aid, pid, fc, fn, fco, ism, isp, pc
        case upt, uet, uppt, cm, fdesc
        case ispl = "ispl"
        case fl, sha1, fs, fta, ico, fatr, isv, def, def2
        case playLong = "play_long"
        case vImg = "v_img"
        case thumb, uo
    }
}

// MARK: - FLItem (文件标签)
struct FLItem: Codable {
    let id, name, sort, color: String?
    let isDefault, updateTime, createTime: Int?

    enum CodingKeys: String, CodingKey {
        case id, name, sort, color
        case isDefault = "is_default"
        case updateTime = "update_time"
        case createTime = "create_time"
    }
}

// MARK: - PathItem (父目录树)
struct PathItem: Codable {
    let name: String?
    let aid, cid, pid, isp: Int?
    let pCid, fv: String?

    enum CodingKeys: String, CodingKey {
        case name, aid, cid, pid, isp
        case pCid = "p_cid"
        case fv
    }
}