import Foundation

// MARK: - FileData115
struct FileData115: Codable {
    let data: [FileItem]?
    let count, sysCount, offset: Int?
    let limit: String?
    let aid: String?
    let cid, isAsc, minSize, maxSize: Int?
    let sysDir, hideData, recordOpenTime: String?
    let star, type: Int?
    let suffix: String?
    let path: [PathItem]?
    let cur, stdir: Int?
    let fields, order: String?
    let state: Bool?
    let code: Int?
    let message: String?

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

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        data = try container.decodeIfPresent([FileItem].self, forKey: .data)
        count = try container.decodeIfPresent(Int.self, forKey: .count)
        sysCount = try container.decodeIfPresent(Int.self, forKey: .sysCount)
        offset = try container.decodeIfPresent(Int.self, forKey: .offset)
        limit = try container.decodeIfPresent(String.self, forKey: .limit)
        aid = try Self.decodeStringOrInt(forKey: .aid, from: container)
        cid = try container.decodeIfPresent(Int.self, forKey: .cid)
        isAsc = try container.decodeIfPresent(Int.self, forKey: .isAsc)
        minSize = try container.decodeIfPresent(Int.self, forKey: .minSize)
        maxSize = try container.decodeIfPresent(Int.self, forKey: .maxSize)
        sysDir = try container.decodeIfPresent(String.self, forKey: .sysDir)
        hideData = try container.decodeIfPresent(String.self, forKey: .hideData)
        recordOpenTime = try container.decodeIfPresent(String.self, forKey: .recordOpenTime)
        star = try container.decodeIfPresent(Int.self, forKey: .star)
        type = try container.decodeIfPresent(Int.self, forKey: .type)
        suffix = try container.decodeIfPresent(String.self, forKey: .suffix)
        path = try container.decodeIfPresent([PathItem].self, forKey: .path)
        cur = try container.decodeIfPresent(Int.self, forKey: .cur)
        stdir = try container.decodeIfPresent(Int.self, forKey: .stdir)
        fields = try container.decodeIfPresent(String.self, forKey: .fields)
        order = try container.decodeIfPresent(String.self, forKey: .order)
        state = try container.decodeIfPresent(Bool.self, forKey: .state)
        code = try container.decodeIfPresent(Int.self, forKey: .code)
        message = try container.decodeIfPresent(String.self, forKey: .message)
    }

    private static func decodeStringOrInt(forKey key: CodingKeys, from container: KeyedDecodingContainer<CodingKeys>) throws -> String? {
        do {
            return try container.decode(String.self, forKey: key)
        } catch {
            let intValue = try container.decode(Int.self, forKey: key)
            return String(intValue)
        }
    }
}

// MARK: - FileItem
struct FileItem: Codable {
    let fid, aid, pid, fc: String?
    let fn, fco, ism: String?
    let isp, iss: Int?
    let ic: String?
    let pc: String?
    let upt, uet, uppt, cm: Int?
    let fdesc: String?
    let ispl, fvs, fuuid: Int?
    let fl: [FLItem]?
    let sha1: String?
    let fs: Int?
    let fta, ico, fatr, ftype, fflabel: String?
    let isv, def, def2, multitrack, playLong: Int?
    let vImg, thumb, uo: String?
    let isTop: Int?
    
    var isVideoFile : Bool {
        guard let fileType = ico else { return false }
        let videoTypes = ["mp4", "mov", "avi", "mkv", "wmv", "flv", "webm"]
        return videoTypes.contains(fileType.lowercased())
    }

    enum CodingKeys: String, CodingKey {
        case fid, aid, pid, fc, fn, fco, ism, isp, iss, ic, pc
        case upt, uet, uppt, cm, fdesc
        case ispl = "ispl"
        case fl, sha1, fs, fta, ico, fatr, isv, def, def2
        case playLong = "play_long"
        case vImg = "v_img"
        case thumb, uo, fvs, fuuid, ftype, fflabel
        case multitrack
        case isTop = "is_top"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        fid = try container.decodeIfPresent(String.self, forKey: .fid)
        aid = try Self.decodeStringOrInt(forKey: .aid, from: container)
        pid = try Self.decodeStringOrInt(forKey: .pid, from: container)
        fc = try container.decodeIfPresent(String.self, forKey: .fc)
        fn = try container.decodeIfPresent(String.self, forKey: .fn)
        fco = try container.decodeIfPresent(String.self, forKey: .fco)
        ism = try container.decodeIfPresent(String.self, forKey: .ism)
        isp = try container.decodeIfPresent(Int.self, forKey: .isp)
        iss = try container.decodeIfPresent(Int.self, forKey: .iss)
        ic = try container.decodeIfPresent(String.self, forKey: .ic)
        pc = try container.decodeIfPresent(String.self, forKey: .pc)
        upt = try container.decodeIfPresent(Int.self, forKey: .upt)
        uet = try container.decodeIfPresent(Int.self, forKey: .uet)
        uppt = try container.decodeIfPresent(Int.self, forKey: .uppt)
        cm = try container.decodeIfPresent(Int.self, forKey: .cm)
        fdesc = try container.decodeIfPresent(String.self, forKey: .fdesc)
        ispl = try container.decodeIfPresent(Int.self, forKey: .ispl)
        fvs = try container.decodeIfPresent(Int.self, forKey: .fvs)
        fuuid = try container.decodeIfPresent(Int.self, forKey: .fuuid)
        fl = try container.decodeIfPresent([FLItem].self, forKey: .fl)
        sha1 = try container.decodeIfPresent(String.self, forKey: .sha1)
        fs = try container.decodeIfPresent(Int.self, forKey: .fs)
        fta = try container.decodeIfPresent(String.self, forKey: .fta)
        ico = try container.decodeIfPresent(String.self, forKey: .ico)
        fatr = try container.decodeIfPresent(String.self, forKey: .fatr)
        ftype = try container.decodeIfPresent(String.self, forKey: .ftype)
        fflabel = try container.decodeIfPresent(String.self, forKey: .fflabel)
        isv = try container.decodeIfPresent(Int.self, forKey: .isv)
        def = try container.decodeIfPresent(Int.self, forKey: .def)
        def2 = try container.decodeIfPresent(Int.self, forKey: .def2)
        multitrack = try container.decodeIfPresent(Int.self, forKey: .multitrack)
        playLong = try container.decodeIfPresent(Int.self, forKey: .playLong)
        vImg = try container.decodeIfPresent(String.self, forKey: .vImg)
        thumb = try container.decodeIfPresent(String.self, forKey: .thumb)
        uo = try container.decodeIfPresent(String.self, forKey: .uo)
        isTop = try container.decodeIfPresent(Int.self, forKey: .isTop)
    }

    private static func decodeStringOrInt(forKey key: CodingKeys, from container: KeyedDecodingContainer<CodingKeys>) throws -> String? {
        do {
            return try container.decode(String.self, forKey: key)
        } catch {
            let intValue = try container.decode(Int.self, forKey: key)
            return String(intValue)
        }
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
    let aid: String?
    let cid: String?
    let isp: String?
    let pid: Int?
    let pCid, fv: String?

    enum CodingKeys: String, CodingKey {
        case name, aid, cid, pid, isp
        case pCid = "p_cid"
        case fv
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        aid = try Self.decodeStringOrInt(forKey: .aid, from: container)
        cid = try Self.decodeStringOrInt(forKey: .cid, from: container)
        pid = try Self.decodeIntOrString(forKey: .pid, from: container)
        isp = try Self.decodeStringOrInt(forKey: .isp, from: container)
        pCid = try container.decodeIfPresent(String.self, forKey: .pCid)
        fv = try container.decodeIfPresent(String.self, forKey: .fv)
    }
    

    
    private static func decodeIntOrString(forKey key: CodingKeys, from container: KeyedDecodingContainer<CodingKeys>) throws -> Int? {
        do {
            return try container.decode(Int.self, forKey: key)
        } catch {
            let stringValue = try container.decode(String.self, forKey: key)
            return Int(stringValue)
        }
    }

    private static func decodeStringOrInt(forKey key: CodingKeys, from container: KeyedDecodingContainer<CodingKeys>) throws -> String? {
        do {
            return try container.decode(String.self, forKey: key)
        } catch {
            let intValue = try container.decode(Int.self, forKey: key)
            return String(intValue)
        }
    }
}
