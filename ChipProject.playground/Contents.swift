import Foundation

// Cоздали хранилище
var storage = [Chip]()

// Cоздали константу состояния потока
let condition = NSCondition()

// Cоздали переменную доступа к потоку
var isAvailable = false

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

// Создаем генерирующий класс(т.к создание экз по 2 секунды, а поток работает 20 сек значит создаст 10 экз. Созданный экземпляр Сhip положили в массив(хранилище) по LIFO(последним пришел -первым ушел)
class GeneratingThread: Thread {
    
    override func main() {
        
        for _ in 0..<10 {
            condition.lock()
            print("Поток GeneratingThread enter")
            isAvailable = true
            storage.insert(Chip.make(), at: 0)
            print("Экземпляр создан и отправлен в хранилище")
            condition.signal()
            print("Сигнал")
            condition.unlock()
            print("Поток GeneratingThread exit")
            GeneratingThread.sleep(forTimeInterval: 2)
        }
    }
}

// Создаем работающий класс, он ожидает появление экземпляра,как только он появляется - идет припайка микросхемы и так со всеми экземплярами. Если в хранилище нет экземпляров - снова находится в ожидании
class WorkingTread: Thread {
    override func main() {
        
        for _ in 0..<10  {
            while (!isAvailable) {
                print("WorkingThread - ждет")
                condition.wait()
            }
            storage.removeFirst().sodering()
            print("Припайка микросхемы")
            
            if storage.count < 1 {
                isAvailable = false
            }
        }
    }
}

let generationThread = GeneratingThread()
let workingThread = WorkingTread()

generationThread.start()
workingThread.start()
