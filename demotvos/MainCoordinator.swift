
import Foundation
import UIKit

class MainCoordinator: Coordinator {
    
    var childCoordinators = [Coordinator]()
    var navigationController: UINavigationController
    
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    func start() {
        let vc = MasterViewController.instantiate()
        vc.coordinator = self
        navigationController.pushViewController(vc, animated: false)
    }
    
    func watchMovie(with detailItem: ContentData) {
        let vc = MovieViewController.instantiate()
        vc.detailItem = detailItem
        vc.coordinator = self
        navigationController.pushViewController(vc, animated: true)
    }
    
    
}
