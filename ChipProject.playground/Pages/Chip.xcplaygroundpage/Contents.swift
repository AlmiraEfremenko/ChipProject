import Foundation

public struct Chip {
    public enum ChipType: UInt32 {
        case small = 1
        case medium
        case big
    }
    
    public let chipType: ChipType
    
    public static func make() -> Chip {
        guard let chipType = Chip.ChipType(rawValue: UInt32(arc4random_uniform(3) + 1)) else {
            fatalError("Incorrect random value")
        }
        return Chip(chipType: chipType)
    }
    
    public func sodering() {
        let soderingTime = chipType.rawValue
        sleep(UInt32(soderingTime))
    }
}

// Создать класс(хранилище) работа осуществляется по принципу LIFO(последним пришел-первым ушел).

class Storage {
    var storage = [Chip]()
    var isAvailable = false
    var condition = NSCondition()
    private var count = 0
    
    var isEmpty: Bool {
        storage.isEmpty
    }
    
    func push(item: Chip) {
        condition.lock()
        isAvailable = true
        storage.append(item)
        count += 1
        print("Чип \(count) в хранилище")
        condition.signal()
        print("Сигнал")
        condition.unlock()
    }
    
    func pop() -> Chip {
        condition.lock()
        while(!isAvailable) {
            condition.wait()
            print("Ждет экземпляр")
        }
        isAvailable = false
        condition.unlock()
        return storage.removeLast()
    }
}

// Генерирующий класс, который создает каждые 2 сек экземпляр Чип, используя метод make

class GeneratingThread: Thread {
    private let storage: Storage
    private var timer = Timer()
    
    init(storage: Storage) {
        self.storage = storage
    }
    
    override func main() {
        timer = Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(getChipCopy), userInfo: nil, repeats: true)
        RunLoop.current.add(timer, forMode: .common)
        RunLoop.current.run(until: Date.init(timeIntervalSinceNow: 20.0))
    }
    
    @objc func getChipCopy() {
        storage.push(item: Chip.make())
    }
}

 //Создаем работающий класс, он ожидает появление экземпляра,как только он появляется - идет припайка микросхемы и так со всеми экземплярами. Если в хранилище нет экземпляров - снова находится в ожидании

class WorkingTread: Thread {
    private var storage: Storage
    
    init(storage: Storage) {
        self.storage = storage
    }
    
    override func main() {
        repeat {
            storage.pop().sodering()
            print("Припайка микросхемы")
        } while storage.isEmpty || storage.isAvailable
    }
}

let storage = Storage()
let generationThread = GeneratingThread(storage: storage)
let workingThread = WorkingTread(storage: storage)
generationThread.start()
workingThread.start()
sleep(20)
generationThread.cancel()
