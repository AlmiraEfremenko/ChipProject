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

// Создать класс(хранилище) работа осуществляется по принципу LIFO(последним пришел-первым ушел). Метод push - добавляет элементы в массив storage,а метод pop - удаляет последний элемент(тоесть последний уходит первым)

class Storage {
    var storage = [Chip]()
    var isAvailable = false
    var condition = NSCondition()
    
    var isEmpty: Bool {
        storage.isEmpty
    }
    
    func push(item: Chip) {
        storage.append(item)
    }
    
    func pop() -> Chip {
        return storage.removeLast()
    }
}

// Генерирующий класс, который создает каждые 2 сек экземпляр Чип, используя метод make

class GeneratingThread: Thread {
    private let storage: Storage
    private var timer = Timer()
    private var count = 0
    
    init(storage: Storage) {
        self.storage = storage
    }
    
    override func main() {
        timer = Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(getChipCopy), userInfo: nil, repeats: true)
        RunLoop.current.add(timer, forMode: .common)
        RunLoop.current.run(until: Date.init(timeIntervalSinceNow: 20.0))
        
    }
    
    @objc func getChipCopy() {
        storage.condition.lock()
        storage.isAvailable = true
        storage.push(item: Chip.make())
        count += 1
        print("Экземпляр \(count) создан и отправлен в хранилище")
        storage.condition.signal()
        print("Сигнал")
        storage.condition.unlock()
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
            while !storage.isAvailable {
                storage.condition.wait()
                print("WorkingThread - ждет")
            }
            storage.pop().sodering()
            print("Припайка микросхемы")
            
            if storage.isEmpty {
                storage.isAvailable = false
            }
        } while storage.isEmpty
    }
}

let storage = Storage()
let generationThread = GeneratingThread(storage: storage)
let workingThread = WorkingTread(storage: storage)
generationThread.start()
workingThread.start()
sleep(20)
generationThread.cancel()
