import Foundation

/// Allocates a configurable amount of dummy memory on request. Useful if you want to make it more 
/// likely that the OS will kill the app while it is in the background.
/// You can use Activity Monitor in Instruments to check when the app gets killed without having the
/// debugger attached.
final class FillMemoryViewModel {

    var allocMemoryButtonEnabled = true
    var allocMemoryButtonTitle = "Fill Memory"
    var spinnerAnimating = false
    var allocMemoryProgress: Float = 0.0

    var targetAmountInBytes: Int64 = FillMemoryViewModel.defaultTargetAmountInBytes() {
        didSet {
            targetAmountLabelText = "Allocate \(byteCountFormatter.string(fromByteCount: targetAmountInBytes)) of memory"
            notifyObservers()
        }
    }
    var minTargetAmountInBytes: Int64 = 0
    var maxTargetAmountInBytes: Int64 {
        return Int64(ProcessInfo.processInfo.physicalMemory)
    }
    var targetAmountLabelText = ""
    var currentAllocAmountLabelText = ""

    private let byteCountFormatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .memory
        return formatter
    }()

    private var dummyMemory: [Int64] = []
    private var allocationQueue = DispatchQueue(label: "dummy memory allocation queue")

    var hasAllocatedDummyMemory: Bool {
        return !dummyMemory.isEmpty
    }

    func resetTargetAmountToDefault() {
        targetAmountInBytes = FillMemoryViewModel.defaultTargetAmountInBytes()
    }

    private static func defaultTargetAmountInBytes() -> Int64 {
        // 50% of the device's physical memory
        return Int64(ProcessInfo.processInfo.physicalMemory) / 2
    }

    func fillOrFreeDummyMemory() {
        if hasAllocatedDummyMemory {
            freeDummyMemory()
        } else {
            allocateDummyMemory()
        }
    }

    private func allocateDummyMemory() {
        allocationQueue.async { [weak self] in
            guard let `self` = self else {
                return
            }

            self.spinnerAnimating = true

            let bytesToAllocate = self.targetAmountInBytes
            let bytesPerElement = Int64(MemoryLayout<Int64>.stride)
            let elementsToAllocate = bytesToAllocate / bytesPerElement
            self.dummyMemory.removeAll(keepingCapacity: true)
            self.dummyMemory.reserveCapacity(Int(elementsToAllocate))

            for n in 1...elementsToAllocate {
                self.dummyMemory.append(n)

                if n % 1000000 == 0 {
                    let bytes = n * bytesPerElement
                    self.allocMemoryProgress = Float(n) / Float(elementsToAllocate)
                    self.currentAllocAmountLabelText = "Allocated \(self.byteCountFormatter.string(fromByteCount: bytes)) of \(self.byteCountFormatter.string(fromByteCount: bytesToAllocate))"
                    self.notifyObservers()
                }
            }

            self.spinnerAnimating = false
            self.allocMemoryProgress = 1.0
            self.allocMemoryButtonTitle = "Free Memory"
            self.notifyObservers()
        }
    }

    private func freeDummyMemory() {
        allocationQueue.async { [weak self] in
            guard let `self` = self else {
                return
            }
            self.dummyMemory.removeAll()
            self.spinnerAnimating = false
            self.allocMemoryProgress = 0.0
            self.currentAllocAmountLabelText = ""
            self.allocMemoryButtonTitle = "Fill Memory"
            self.notifyObservers()
        }
    }
    
    fileprivate var observers: [(FillMemoryViewModel) -> ()] = []
}

extension FillMemoryViewModel: Observable {
    func addObserver(callback: @escaping (FillMemoryViewModel) -> ()) {
        observers.append(callback)
    }

    func notifyObservers() {
        for callback in observers {
            callback(self)
        }
    }
}
