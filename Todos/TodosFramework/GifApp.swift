import UIKit
import VirtualViews

public struct GifApp: RootComponent {
    var image: UIImage?
    var loading: Bool
    public enum Message: Equatable {
        case reload
        case receiveMetadata(Data?)
        case receiveGif(Data?)
    }
    
    public init() {
        image = nil
        loading = false
    }
    
    var gifURL: URL {
        return URL(string: "https://api.giphy.com/v1/gifs/random?api_key=dc6zaTOxFJmzC")!
    }
    
    public mutating func send(_ msg: Message) -> [Command<Message>] {
        switch msg {
        case .reload:
            let urlRequest = URLRequest(url: gifURL)
            loading = true
            return [.request(urlRequest, available: { .receiveMetadata($0) })]
        case .receiveMetadata(let data):
            guard let data = data, let url = extractGIFURL(data: data) else {
                loading = false
                return []
            }
            return [.request(URLRequest(url: url), available: { .receiveGif($0) })]
        case .receiveGif(let data):
            defer { loading = false }
            guard let d = data else {
                return []
            }
            image = UIImage(data: d)
        }
        return []
    }
    
    public var viewController: ViewController<Message> {
        return .viewController(
            .stackView(views: loading ? [.activityIndicator(style: .gray)] : [
                .imageView(image: image),
                .button(text: "Reload", onTap: .reload)
            ])
        )
    }
    
    public var subscriptions: [Subscription<Message>] {
        return []
    }
}

func extractGIFURL(data: Data) -> URL? {
    guard let json = try? JSONSerialization.jsonObject(with: data, options: []),
    let dict = json as? [String:Any],
    let d = dict["data"] as? [String:Any],
        let urlString = d["image_url"] as? String else { return nil }
    return URL(string: urlString)
}

public func ==(lhs: GifApp.Message, rhs: GifApp.Message) -> Bool {
    switch (lhs, rhs) {
    case (.reload, .reload): return true
    case (.receiveGif(let l), (.receiveGif(let r))): return l == r
    case (.receiveMetadata(let l), .receiveMetadata(let r)): return l == r
    default: return false
    }
}

// Tests:
//import XCTest
//
//class GifTests: XCTestCase {
//    func testReload() {
//        var sample = GifApp(image: nil)
//        let commands = sample.send(.reload)
//        XCTAssert(commands.count == 1)
//        guard case let .request(url, available: transform) = commands[0] else {
//            XCTFail("Expected a URL request")
//            return
//        }
//        let randomData = Data()
//        XCTAssertTrue(transform(randomData) == .receiveGif(randomData))
//    }
//}

