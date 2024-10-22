import Foundation

// pflags
public struct SFTPOpenFileFlags: OptionSet, CustomDebugStringConvertible, Sendable {
    public var rawValue: UInt32
    
    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }
    
    /// SSH_FXF_READ
    ///
    /// Open the file for reading.
    public static let read = SFTPOpenFileFlags(rawValue: 0x00000001)
    
    /// SSH_FXF_WRITE
    ///
    /// Open the file for writing.  If both this and SSH_FXF_READ are
    /// specified, the file is opened for both reading and writing.
    public static let write = SFTPOpenFileFlags(rawValue: 0x00000002)
    
    /// SSH_FXF_APPEND
    ///
    /// Force all writes to append data at the end of the file.
    public static let append = SFTPOpenFileFlags(rawValue: 0x00000004)
    
    /// SSH_FXF_CREAT
    ///
    /// If this flag is specified, then a new file will be created if one
    /// does not already exist (if O_TRUNC is specified, the new file will
    /// be truncated to zero length if it previously exists).
    public static let create = SFTPOpenFileFlags(rawValue: 0x00000008)
    
    /// SSH_FXF_TRUNC
    ///
    /// Forces an existing file with the same name to be truncated to zero
    /// length when creating a file by specifying SSH_FXF_CREAT.
    /// SSH_FXF_CREAT MUST also be specified if this flag is used.
    public static let truncate = SFTPOpenFileFlags(rawValue: 0x00000010)
    
    /// SSH_FXF_EXCL
    ///
    /// Causes the request to fail if the named file already exists.
    /// SSH_FXF_CREAT MUST also be specified if this flag is used.
    public static let forceCreate = SFTPOpenFileFlags(rawValue: 0x00000020)
	public static let exclusive = forceCreate
    
    public var debugDescription: String {
        String(format: "0x%08x", self.rawValue)
    }
}

public enum SFTPFileType: RawRepresentable, Hashable, CustomDebugStringConvertible {
	/// S_IFMT
	public static let mask:UInt32 = 0xF000
	
	/// S_IFSOCK
	case socket
	/// S_IFLNK
	case symbolicLink
	/// S_IFREG
	case regularFile
	/// S_IFBLK
	case blockDevice
	/// S_IFDIR
	case directory
	/// S_IFCHR
	case characterDevice
	/// S_IFIFO
	case fifo
	case unknown(UInt32)
	
	public var rawValue: UInt32 {
		switch self {
		case .socket: return 0xC000
		case .symbolicLink: return 0xA000
		case .regularFile: return 0x8000
		case .blockDevice: return 0x6000
		case .directory: return 0x4000
		case .characterDevice: return 0x2000
		case .fifo: return 0x1000
		case .unknown(let value): return value
		}
	}
	
	public init?(rawValue: UInt32) {
		switch rawValue {
		case 0xC000: self = .socket
		case 0xA000: self = .symbolicLink
		case 0x8000: self = .regularFile
		case 0x6000: self = .blockDevice
		case 0x4000: self = .directory
		case 0x2000: self = .characterDevice
		case 0x1000: self = .fifo
		case let value: self = .unknown(value)
		}
	}
	
	public init(_ rawValue: UInt32) {
		self.init(rawValue: rawValue)!
	}
	
	public var debugDescription: String {
		switch self {
		case .socket: return "Socket"
		case .symbolicLink: return "Symbolic Link"
		case .regularFile: return "Regular File"
		case .blockDevice: return "Block Device"
		case .directory: return "Directory"
		case .characterDevice: return "Character Device"
		case .fifo: return "FIFO"
		case .unknown(let value): return "Unknown(\(String(format: "0x%04x", value)))"
		}
	}
}

public struct SFTPFilePermissions : OptionSet, CustomDebugStringConvertible, Sendable {
	public struct User : OptionSet, CustomDebugStringConvertible, Sendable {
		public static let mask:UInt16 = 0x01C0
		
		public var rawValue: UInt16
		
		public init(rawValue: UInt16) {
			self.rawValue = rawValue
		}
		
		/// S_IRUSR
		public static let read = User(rawValue: 0x0100)
		/// S_IWUSR
		public static let write = User(rawValue: 0x0080)
		/// S_IXUSR
		public static let execute = User(rawValue: 0x0040)
		
		public static let all = User(rawValue: mask)
		
		public var debugDescription: String {
			String(format: "0x%04x", self.rawValue)
		}
	}
	
	public struct Group : OptionSet, CustomDebugStringConvertible, Sendable {
		public static let mask:UInt16 = 0x0038
		
		public var rawValue: UInt16
		
		public init(rawValue: UInt16) {
			self.rawValue = rawValue
		}
		
		/// S_IRGRP
		public static let read = Group(rawValue: 0x0020)
		/// S_IWGRP
		public static let write = Group(rawValue: 0x0010)
		/// S_IXGRP
		public static let execute = Group(rawValue: 0x0008)
		
		public static let all = Group(rawValue: mask)
		
		public var debugDescription: String {
			String(format: "0x%04x", self.rawValue)
		}
	}
	
	public struct Others : OptionSet, CustomDebugStringConvertible, Sendable {
		public static let mask:UInt16 = 0x0007
		
		public var rawValue: UInt16
		
		public init(rawValue: UInt16) {
			self.rawValue = rawValue
		}
		
		/// S_IROTH
		public static let read = Others(rawValue: 0x0004)
		/// S_IWOTH
		public static let write = Others(rawValue: 0x0002)
		/// S_IXOTH
		public static let execute = Others(rawValue: 0x0001)
		
		public static let all = Others(rawValue: mask)
		
		public var debugDescription: String {
			String(format: "0x%04x", self.rawValue)
		}
	}
	
	/// ~S_IFMT
	public static let mask:UInt16 = 0x0FFF
	
	public var rawValue: UInt16
	
	public init(rawValue: UInt16) {
		self.rawValue = rawValue
	}
	
	public var user : User {
		User(rawValue: self.rawValue & User.mask)
	}
	public var group : Group {
		Group(rawValue: self.rawValue & Group.mask)
	}
	public var others : Others {
		Others(rawValue: self.rawValue & Others.mask)
	}
	
	/// S_ISUID
	public static let setUID = SFTPFilePermissions(rawValue: 0x0800)
	/// S_ISGID
	public static let setGID = SFTPFilePermissions(rawValue: 0x0400)
	/// S_ISVTX
	public static let sticky = SFTPFilePermissions(rawValue: 0x0200)
	
	/// S_IRUSR
	public static let user_read = SFTPFilePermissions(rawValue: User.read.rawValue)
	/// S_IWUSR
	public static let user_write = SFTPFilePermissions(rawValue: User.write.rawValue)
	/// S_IXUSR
	public static let user_execute = SFTPFilePermissions(rawValue: User.execute.rawValue)
	
	/// S_IRGRP
	public static let group_read = SFTPFilePermissions(rawValue: Group.read.rawValue)
	/// S_IWGRP
	public static let group_write = SFTPFilePermissions(rawValue: Group.write.rawValue)
	/// S_IXGRP
	public static let group_execute = SFTPFilePermissions(rawValue: Group.execute.rawValue)
	
	/// S_IROTH
	public static let others_read = SFTPFilePermissions(rawValue: Others.read.rawValue)
	/// S_IWOTH
	public static let others_write = SFTPFilePermissions(rawValue: Others.write.rawValue)
	/// S_IXOTH
	public static let others_execute = SFTPFilePermissions(rawValue: Others.execute.rawValue)
	
	public static let all = SFTPFilePermissions(rawValue: mask)
	
	public var debugDescription: String {
		String(format: "0x%04x", self.rawValue)
	}
}

public struct SFTPFileMode : OptionSet, CustomDebugStringConvertible, Sendable {
	public var rawValue: UInt32
	
	public init(rawValue: UInt32) {
		self.rawValue = rawValue
	}
	
	public init (type:SFTPFileType, permissions:SFTPFilePermissions) {
		self.rawValue = type.rawValue | UInt32(permissions.rawValue)
	}
	
	public var type : SFTPFileType? {
		SFTPFileType(rawValue: self.rawValue & SFTPFileType.mask)
	}
	
	public var permissions : SFTPFilePermissions {
		SFTPFilePermissions(rawValue: UInt16(self.rawValue) & SFTPFilePermissions.mask)
	}
	
	/// S_IFSOCK
	public static let socket = SFTPFileMode(rawValue: SFTPFileType.socket.rawValue)
	/// S_IFLNK
	public static let symbolicLink = SFTPFileMode(rawValue: SFTPFileType.symbolicLink.rawValue)
	/// S_IFREG
	public static let regularFile = SFTPFileMode(rawValue: SFTPFileType.regularFile.rawValue)
	/// S_IFBLK
	public static let blockDevice = SFTPFileMode(rawValue: SFTPFileType.blockDevice.rawValue)
	/// S_IFDIR
	public static let directory = SFTPFileMode(rawValue: SFTPFileType.directory.rawValue)
	/// S_IFCHR
	public static let characterDevice = SFTPFileMode(rawValue: SFTPFileType.characterDevice.rawValue)
	/// S_IFIFO
	public static let fifo = SFTPFileMode(rawValue: SFTPFileType.fifo.rawValue)
	
	/// S_ISUID
	public static let setUID = SFTPFileMode(rawValue: UInt32(SFTPFilePermissions.setUID.rawValue))
	/// S_ISGID
	public static let setGID = SFTPFileMode(rawValue: UInt32(SFTPFilePermissions.setGID.rawValue))
	/// S_ISVTX
	public static let sticky = SFTPFileMode(rawValue: UInt32(SFTPFilePermissions.sticky.rawValue))
	
	/// S_IRUSR
	public static let user_read = SFTPFileMode(rawValue: UInt32(SFTPFilePermissions.user_read.rawValue))
	/// S_IWUSR
	public static let user_write = SFTPFileMode(rawValue: UInt32(SFTPFilePermissions.user_write.rawValue))
	/// S_IXUSR
	public static let user_execute = SFTPFileMode(rawValue: UInt32(SFTPFilePermissions.user_execute.rawValue))
	
	/// S_IRGRP
	public static let group_read = SFTPFileMode(rawValue: UInt32(SFTPFilePermissions.group_read.rawValue))
	/// S_IWGRP
	public static let group_write = SFTPFileMode(rawValue: UInt32(SFTPFilePermissions.group_write.rawValue))
	/// S_IXGRP
	public static let group_execute = SFTPFileMode(rawValue: UInt32(SFTPFilePermissions.group_execute.rawValue))
	
	/// S_IROTH
	public static let others_read = SFTPFileMode(rawValue: UInt32(SFTPFilePermissions.others_read.rawValue))
	/// S_IWOTH
	public static let others_write = SFTPFileMode(rawValue: UInt32(SFTPFilePermissions.others_write.rawValue))
	/// S_IXOTH
	public static let others_execute = SFTPFileMode(rawValue: UInt32(SFTPFilePermissions.others_execute.rawValue))
	
	public var debugDescription: String {
		"{type: \(type?.debugDescription ?? String(format: "Unknown(%04x)", rawValue & SFTPFileType.mask)), permissions: \(permissions.debugDescription)}"
	}
}

public struct SFTPFileAttributes: CustomDebugStringConvertible {
    public struct Flags: OptionSet {
        public var rawValue: UInt32
        
        public init(rawValue: UInt32) {
            self.rawValue = rawValue
        }
        
        public static let size = Flags(rawValue: 0x00000001)
        public static let uidgid = Flags(rawValue: 0x00000002)
        public static let permissions = Flags(rawValue: 0x00000004)
        public static let acmodtime = Flags(rawValue: 0x00000008)
        public static let extended = Flags(rawValue: 0x80000000)
    }
    
    public struct UserGroupId {
        public let userId: UInt32
        public let groupId: UInt32
        
        public init(
            userId: UInt32,
            groupId: UInt32
        ) {
            self.userId = userId
            self.groupId = groupId
        }
    }
    
    public struct AccessModificationTime {
        // Both written as UInt32 seconds since jan 1 1970 as UTC
        public let accessTime: Date
        public let modificationTime: Date
        
        public init(
            accessTime: Date,
            modificationTime: Date
        ) {
            self.accessTime = accessTime
            self.modificationTime = modificationTime
        }
    }
    
    public var flags: Flags {
        var flags: Flags = []
        
        if size != nil {
            flags.insert(.size)
        }
        
        if uidgid != nil {
            flags.insert(.uidgid)
        }
        
        if permissions != nil {
            flags.insert(.permissions)
        }
        
        if accessModificationTime != nil {
            flags.insert(.acmodtime)
        }
        
        if !extended.isEmpty {
            flags.insert(.extended)
        }
        
        return flags
    }
    
    public var size: UInt64?
    public var uidgid: UserGroupId?
	public var uid: UInt32? { uidgid?.userId }
	public var gid: UInt32? { uidgid?.groupId }
    
    public var mode: SFTPFileMode?
	public var type: SFTPFileType? { mode?.type }
	public var permissions: SFTPFilePermissions? { mode?.permissions }
    public var accessModificationTime: AccessModificationTime?
	public var accessTime: Date? { accessModificationTime?.accessTime }
	public var modificationTime: Date? { accessModificationTime?.modificationTime }
    public var extended = [(String, String)]()
    
    public init(size: UInt64? = nil, accessModificationTime: AccessModificationTime? = nil) {
        self.size = size
        self.accessModificationTime = accessModificationTime
    }
	
	public init(size: UInt64? = nil, accessTime: Date, modificationTime: Date) {
		self.size = size
		self.accessModificationTime = AccessModificationTime(accessTime: accessTime, modificationTime: modificationTime)
	}
    
    public static let none = SFTPFileAttributes()
    public static let all: SFTPFileAttributes = {
        var attr = SFTPFileAttributes()
//        attr.permissions = 777
        return attr
    }()
    
	public var debugDescription: String { "{type: \(String(describing: type)), permissions: \(String(describing: permissions)), size: \(String(describing: size)), uid: \(String(describing: uid)), gid: \(String(describing: gid))}" }
}

