import AppKit
import CoreGraphics
import Foundation

struct VisionResult: Sendable {
    let cocoaRect: CGRect
    let confidence: Double
    let hint: String?
}

/// Request-scoped screen capture for the explicitly enabled vision fallback.
struct VisionService {
    private struct RequestBody: Encodable {
        let image_base64: String
        let target_label: String
        let step_instruction: String?
        let high_accuracy: Bool
    }

    private struct ResponseBody: Decodable {
        let found: Bool?
        let bbox: [Double]?
        let confidence: Double?
        let hint: String?
    }

    let baseURL: URL

    init(baseURL: URL = BackendClient().baseURL) {
        self.baseURL = baseURL
    }

    @MainActor
    func locate(label: String, instruction: String?, on screen: NSScreen) async -> VisionResult? {
        guard CGPreflightScreenCaptureAccess() || CGRequestScreenCaptureAccess() else { return nil }
        guard let displayNumber = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber,
              let image = CGDisplayCreateImage(CGDirectDisplayID(displayNumber.uint32Value)) else { return nil }
        let representation = NSBitmapImageRep(cgImage: image)
        guard let encoded = representation.representation(using: .jpeg, properties: [.compressionFactor: 0.78]) else { return nil }

        let body = RequestBody(image_base64: encoded.base64EncodedString(),
                               target_label: label,
                               step_instruction: instruction,
                               high_accuracy: false)
        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else { return nil }
        components.path = "/nova-vision"; components.query = nil; components.fragment = nil
        guard let url = components.url, url.scheme == baseURL.scheme, url.host == baseURL.host else { return nil }
        var request = URLRequest(url: url, timeoutInterval: 90)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(body)
        guard request.httpBody != nil else { return nil }

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode),
                  let result = try? JSONDecoder().decode(ResponseBody.self, from: data),
                  result.found == true, let confidence = result.confidence, confidence >= 0.55,
                  let bbox = result.bbox, bbox.count == 4,
                  let rect = CoordinateSpace.bbox1000ToCocoa(bbox, screenFrame: screen.frame) else { return nil }
            return VisionResult(cocoaRect: rect, confidence: confidence, hint: result.hint)
        } catch {
            return nil
        }
    }
}
