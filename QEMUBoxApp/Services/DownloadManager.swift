import Foundation
import Combine

class DownloadManager: ObservableObject {
    static let shared = DownloadManager()
    
    @Published var downloads: [DownloadTask] = []
    @Published var totalProgress: Double = 0
    
    private var urlSessions: [String: URLSession] = [:]
    private let fileManager = FileManager.default
    private let downloadsDirectoryURL: URL
    private let vmManager = VMManager.shared
    
    init() {
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        downloadsDirectoryURL = documentsURL.appendingPathComponent("QEMUBox_Downloads", isDirectory: true)
        try? fileManager.createDirectory(at: downloadsDirectoryURL, withIntermediateDirectories: true)
        
        restoreDownloads()
    }
    
    // MARK: - Download OS
    func downloadOS(_ os: OSImage, vmName: String, cpuCores: Int, ramGB: Int, completion: @escaping (Bool) -> Void) {
        let downloadTask = DownloadTask(
            id: UUID().uuidString,
            osId: os.id,
            osName: os.name,
            downloadURL: os.downloadURL,
            fileName: "\(os.name)-\(os.version).iso",
            totalSize: os.size,
            vmName: vmName,
            cpuCores: cpuCores,
            ramGB: ramGB,
            progress: 0,
            status: .downloading,
            createdAt: Date()
        )
        
        DispatchQueue.main.async {
            self.downloads.append(downloadTask)
        }
        
        let destinationURL = downloadsDirectoryURL.appendingPathComponent(downloadTask.fileName)
        
        downloadFile(from: URL(string: os.downloadURL)!, to: destinationURL, task: downloadTask) { success in
            if success {
                self.createVMFromDownload(downloadTask, osImagePath: destinationURL)
            }
            completion(success)
        }
    }
    
    // MARK: - Download File
    private func downloadFile(from url: URL, to destinationURL: URL, task: DownloadTask, completion: @escaping (Bool) -> Void) {
        var request = URLRequest(url: url)
        request.timeoutInterval = TimeInterval(Int.max)
        
        let config = URLSessionConfiguration.default
        config.waitsForConnectivity = true
        let session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        urlSessions[task.id] = session
        
        let downloadTask = session.downloadTask(with: request) { [weak self] tempURL, response, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Download error: \(error.localizedDescription)")
                self.updateDownloadStatus(task.id, status: .failed)
                completion(false)
                return
            }
            
            guard let tempURL = tempURL else {
                self.updateDownloadStatus(task.id, status: .failed)
                completion(false)
                return
            }
            
            do {
                try self.fileManager.moveItem(at: tempURL, to: destinationURL)
                self.updateDownloadStatus(task.id, status: .completed)
                completion(true)
            } catch {
                print("File move error: \(error.localizedDescription)")
                self.updateDownloadStatus(task.id, status: .failed)
                completion(false)
            }
        }
        
        downloadTask.resume()
    }
    
    // MARK: - Create VM from Download
    private func createVMFromDownload(_ downloadTask: DownloadTask, osImagePath: URL) {
        let vm = vmManager.createVM(
            name: downloadTask.vmName,
            osType: downloadTask.osName,
            osPath: osImagePath,
            cpuCores: downloadTask.cpuCores,
            ramGB: downloadTask.ramGB
        )
        
        print("VM created: \(vm.name)")
    }
    
    // MARK: - Pause Download
    func pauseDownload(_ taskId: String) {
        if let session = urlSessions[taskId] {
            session.invalidateAndCancel()
            updateDownloadStatus(taskId, status: .paused)
        }
    }
    
    // MARK: - Resume Download
    func resumeDownload(_ taskId: String) {
        if let download = downloads.first(where: { $0.id == taskId }) {
            updateDownloadStatus(taskId, status: .downloading)
        }
    }
    
    // MARK: - Cancel Download
    func cancelDownload(_ taskId: String) {
        if let session = urlSessions[taskId] {
            session.invalidateAndCancel()
            urlSessions.removeValue(forKey: taskId)
        }
        
        downloads.removeAll { $0.id == taskId }
        
        // Remove file
        if let download = downloads.first(where: { $0.id == taskId }) {
            let fileURL = downloadsDirectoryURL.appendingPathComponent(download.fileName)
            try? fileManager.removeItem(at: fileURL)
        }
    }
    
    // MARK: - Update Download Status
    private func updateDownloadStatus(_ taskId: String, status: DownloadStatus) {
        DispatchQueue.main.async {
            if let index = self.downloads.firstIndex(where: { $0.id == taskId }) {
                self.downloads[index].status = status
            }
        }
    }
    
    // MARK: - Update Progress
    private func updateProgress(_ taskId: String, progress: Double) {
        DispatchQueue.main.async {
            if let index = self.downloads.firstIndex(where: { $0.id == taskId }) {
                self.downloads[index].progress = progress
                self.updateTotalProgress()
            }
        }
    }
    
    // MARK: - Update Total Progress
    private func updateTotalProgress() {
        guard !downloads.isEmpty else {
            totalProgress = 0
            return
        }
        
        let avgProgress = downloads.map { $0.progress }.reduce(0, +) / Double(downloads.count)
        totalProgress = avgProgress
    }
    
    // MARK: - Restore Downloads
    func restoreDownloads() {
        // Scan downloads directory for incomplete files
        // Restore download tasks from persistent storage
    }
}

// MARK: - URLSessionDelegate
extension DownloadManager: URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        // Handled in downloadFile completion
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard totalBytesExpectedToWrite > 0 else { return }
        
        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        
        // Find corresponding task
        for download in downloads {
            if let session = urlSessions[download.id], session.configuration == downloadTask.session?.configuration {
                updateProgress(download.id, progress: progress)
            }
        }
    }
}

// MARK: - DownloadTask Model
struct DownloadTask: Identifiable, Codable {
    let id: String
    let osId: String
    let osName: String
    let downloadURL: String
    let fileName: String
    let totalSize: UInt64
    let vmName: String
    let cpuCores: Int
    let ramGB: Int
    var progress: Double
    var status: DownloadStatus
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, osId, osName, downloadURL, fileName, totalSize, vmName, cpuCores, ramGB, progress, status, createdAt
    }
}

// MARK: - DownloadStatus Enum
enum DownloadStatus: String, Codable {
    case downloading
    case paused
    case completed
    case failed
}
