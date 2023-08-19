import UIKit
import FirebaseFirestore
import FirebaseFirestoreSwift

class FirestoreCRUDViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    var buildings: [Building] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        fetchBuildingsFromFirestore()
    }
    
    func fetchBuildingsFromFirestore() {
        let db = Firestore.firestore()
        db.collection("buildings").getDocuments { (snapshot, error) in
            if let error = error {
                print("Error fetching documents: \(error)")
                return
            }
            
            var fetchedBuildings: [Building] = []
            
            for document in snapshot!.documents {
                let data = document.data()
                
                do {
                    var building = try Firestore.Decoder().decode(Building.self, from: data)
                    building.documentID = document.documentID // Set the documentID
                    
                    // Fetch the image URL from the document data
                    if let imageURL = data["imageURL"] as? String {
                        building.imageURL = imageURL
                    }
                    
                    fetchedBuildings.append(building)
                } catch {
                    print("Error decoding building data: \(error)")
                }
            }
            
            DispatchQueue.main.async {
                self.buildings = fetchedBuildings
                self.tableView.reloadData()
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return buildings.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BuildingCell", for: indexPath) as! BuildingTableViewCell
        
        let building = buildings[indexPath.row]
        
        cell.nameLabel?.text = building.name
        cell.dateBuiltLabel?.text = building.dateBuilt
        
        // Load and display the building image
        if let imageURL = URL(string: building.imageURL) {
            URLSession.shared.dataTask(with: imageURL) { data, response, error in
                if let data = data {
                    DispatchQueue.main.async {
                        cell.buildingImageView.image = UIImage(data: data)
                    }
                }
            }.resume()
        }
        
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "AddEditSegue", sender: indexPath)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let building = buildings[indexPath.row]
            showDeleteConfirmationAlert(for: building) { confirmed in
                if confirmed {
                    self.deleteBuilding(at: indexPath)
                }
            }
        }
    }
    
    @IBAction func addButtonPressed(_ sender: UIButton) {
        performSegue(withIdentifier: "AddEditSegue", sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "AddEditSegue" {
            if let addEditVC = segue.destination as? AddEditBuildingViewController {
                addEditVC.buildingViewController = self
                if let indexPath = sender as? IndexPath {
                    let building = buildings[indexPath.row]
                    addEditVC.building = building
                } else {
                    addEditVC.building = nil
                }
                
                addEditVC.buildingUpdateCallback = { [weak self] in
                    self?.fetchBuildingsFromFirestore()
                }
            }
        }
    }
    
    func showDeleteConfirmationAlert(for building: Building, completion: @escaping (Bool) -> Void) {
        let alert = UIAlertController(title: "Delete Building", message: "Are you sure you want to delete this building?", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
            completion(false)
        })
        
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
            completion(true)
        })
        
        present(alert, animated: true, completion: nil)
    }
    
    func deleteBuilding(at indexPath: IndexPath) {
        let building = buildings[indexPath.row]
        
        guard let documentID = building.documentID else {
            print("Invalid document ID")
            return
        }
        
        let db = Firestore.firestore()
        db.collection("buildings").document(documentID).delete { [weak self] error in
            if let error = error {
                print("Error deleting document: \(error)")
            } else {
                DispatchQueue.main.async {
                    print("Building deleted successfully.")
                    self?.buildings.remove(at: indexPath.row)
                    self?.tableView.deleteRows(at: [indexPath], with: .fade)
                }
            }
        }
    }
}
