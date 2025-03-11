import Foundation

enum ContentType {
    case Movie
    case Content
    case Settings
    case WebSdkView
    case MovieExtension
}

class ContentData {
    
    let urlString: String
    let title: String
    let mediaId: String
    let contentId: String
    let contentType: ContentType
    let live: Bool
    let googleIMASupport: Bool
    
    init(title: String, urlString: String, mediaId: String, contentId: String, contentType: ContentType, live: Bool, googleIMASupport: Bool = false) {
        self.urlString = urlString
        self.title = title
        self.mediaId = mediaId
        self.contentId = contentId
        self.contentType = contentType
        self.live = live
        self.googleIMASupport = googleIMASupport
    }
    
    class func sampleData() -> [ContentData] {
        return [
            ContentData(title: "VoD Manual", urlString: "https://demo-config-preproduction.sensic.net/video/video3.mp4", mediaId: "s2sdemomediaid_ssa_ios_new", contentId: "default", contentType: .Movie, live: false),
            ContentData(title: "Live Manual", urlString: "https://live-hls-web-aje.getaj.net/AJE/01.m3u8", mediaId: "s2sdemomediaid_ssa_ios_new", contentId: "default", contentType: .Movie, live: true)
        ]
    }
    
}
