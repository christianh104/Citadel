import NIO
import Logging

/// A "handle" for accessing a directory that has been successfully opened on an SFTP server. Directory handles support reading.
public final class SFTPDirectory: AsyncSequence {
	/// Indicates whether the directory's handle was still valid at the time the getter was called.
	public private(set) var isActive: Bool
	
	/// The raw buffer whose contents are were contained in the `.handle()` result from the SFTP server.
	/// Used for performing operations on the open directory.
	///
	/// - Note: Make this `private` when concurrency isn't in a separate file anymore.
	internal let handle: SFTPFile.SFTPFileHandle
	
	internal let path: String
	
	/// The `SFTPClient` this handle belongs to.
	///
	/// - Note: Make this `private` when concurrency isn't in a separate file anymore.
	internal let client: SFTPClient
	
	/// Wrap a file handle received from an SFTP server in an `SFTPDirectory`. The object should be treated as
	/// having taken ownership of the handle; nothing else should continue to use the handle.
	///
	/// Do not create instances of `SFTPDirectory` yourself; use `SFTPClient.openDirectory()` or `SFTPClient.withDirectory()`.
	internal init(client: SFTPClient, path: String, handle: SFTPFile.SFTPFileHandle) {
		self.isActive = true
		self.handle = handle
		self.client = client
		self.path = path
	}
	
	/// A `Logger` for the directory. Uses the logger of the client that opened the directory.
	public var logger: Logging.Logger { self.client.logger }
	
	deinit {
		if client.isActive && self.isActive {
			self.logger.warning("SFTPDirectory deallocated without being closed first")
		}
	}
	
	/// Read the attributes of the directory. This is equivalent to the `fstat()` system call.
	public func readAttributes() async throws -> SFTPFileAttributes {
		guard self.isActive else { throw SFTPError.fileHandleInvalid }
		
		guard case .attributes(let attributes) = try await self.client.sendRequest(.fstat(.init(
			requestId: self.client.allocateRequestId(),
			handle: handle
		))) else {
			self.logger.warning("SFTP server returned bad response to directory attributes request, this is a protocol error")
			throw SFTPError.invalidResponse
		}
		
		return attributes.attributes
	}
	/// Read a batch of entries from the directory, or nil if there are no more entries to read.
	public func read() async throws -> [SFTPPathComponent]? {
		guard self.isActive else { throw SFTPError.fileHandleInvalid }
		
        return try await self.client._readDirectory(handle: self.handle)
	}
	
	/// Read all entries in the directory.
	public func readAll() async throws -> [SFTPPathComponent] {
        var entries = [SFTPPathComponent]()
		
		self.logger.debug("SFTP starting chunked read operation on directory \(self.handle.sftpHandleDebugDescription)")
		
		while let chunk = try await self.read() {
            entries.append(contentsOf: chunk)
		}
		
		self.logger.debug("SFTP completed chunked read operation on directory \(self.handle.sftpHandleDebugDescription)")
		return entries
	}
	
	/// Iterate entries in the directory.
	public func makeAsyncIterator() -> SFTPDirectoryIterator {
		return SFTPDirectoryIterator(self)
	}
	
	/// Close the directory. No further operations may take place on the directory after it is closed. A directory _must_ be closed
	/// before the last reference to it goes away.
	///
	/// - Note: Directories are automatically closed if the SFTP channel is shut down, but it is strongly recommended that
	///  callers explicitly close the directory anyway, as multiple close operations are idempotent. The "close before
	///  deinit" requirement is enforced in debug builds by an assertion; violations are ignored in release builds.
	public func close() async throws -> Void {
		guard self.isActive else {
			// Don't blow up if close is called on an invalid handle; it's too easy for it to happen by accident.
			return
		}
		
		self.logger.debug("SFTP closing and invalidating directory \(self.handle.sftpHandleDebugDescription)")
		
		self.isActive = false
		let result = try await self.client.sendRequest(.closeFile(.init(requestId: self.client.allocateRequestId(), handle: self.handle)))
		
		guard case .status(let status) = result else {
			throw SFTPError.invalidResponse
		}
		
		guard status.errorCode == .ok else {
			throw SFTPError.errorStatus(status)
		}
		
		self.logger.debug("SFTP closed directory \(self.handle.sftpHandleDebugDescription)")
	}
}

public struct SFTPDirectoryIterator : AsyncIteratorProtocol {
	internal let directory: SFTPDirectory
	
	init(_ directory: SFTPDirectory) {
		self.directory = directory
	}
	
	public func next() async throws -> [SFTPPathComponent]? {
		let entries = try await directory.read()
		if entries == nil {
			try? await directory.close()
		}
		return entries
	}
}
