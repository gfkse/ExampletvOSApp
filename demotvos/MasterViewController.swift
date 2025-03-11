import UIKit
import s2s_sdk_tvos_agent_only

class MasterViewController: UIViewController, Storyboarded, UITableViewDelegate, UITableViewDataSource {

    weak var coordinator: MainCoordinator?
    
    var objects = ContentData.sampleData()
    var optin = true
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "S2S SDK"
    }
    
    // MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return objects.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        let object = objects[(indexPath as NSIndexPath).row]
        cell.textLabel!.text = "\(object.title) (\(object.contentType))"
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let object = objects[(indexPath as NSIndexPath).row]
        
        switch object.contentType {
        case .Movie:
            if !object.googleIMASupport {
                coordinator?.watchMovie(with: object)
            }
        case .MovieExtension:
            print("")
            
        case .Content, .Settings, .WebSdkView:
            print("")
        }
    }
    
}
