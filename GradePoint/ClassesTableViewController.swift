//
//  ClassesTableViewController.swift
//  GradePoint
//
//  Created by Luis Padron on 7/16/17.
//  Copyright © 2017 Luis Padron. All rights reserved.
//

import UIKit
import RealmSwift
import UIEmptyState
import LPSnackbar

class ClassesTableViewController: UITableViewController {
    
    // MARK: Properties
    
    private var notificationTokens: [NotificationToken] = [NotificationToken]()
    
    private var semesters: [Semester] {
        get {
            return generateSemesters()
        }
    }
    
    private var classes: [Results<Class>] = [Results<Class>]()
    
    // MARK: View Handeling
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup delegation a
        if #available(iOS 11.0, *) {
            navigationController?.navigationBar.prefersLargeTitles = true
        }
        splitViewController?.delegate = self
        splitViewController?.preferredDisplayMode = .allVisible
        tableView.scrollsToTop = true
        emptyStateDelegate = self
        emptyStateDataSource = self
        
        // Remove seperator lines from empty cells, and remove white background around navbars
        tableView.tableFooterView = UIView(frame: CGRect.zero)
        tableView.separatorColor = UIColor.tableViewSeperator
        tableView.backgroundView = UIView()
        
        // Setup tableview estimates
        tableView.estimatedRowHeight = 60
        tableView.estimatedSectionHeaderHeight = 44
        tableView.estimatedSectionFooterHeight = 0
        
        // Get all classes on load
        loadClasses()
        
        // Add notifications for Class object changes
        for (i, objs) in classes.enumerated() {
            registerNotifications(for: objs, in: i)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        reloadEmptyState()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        clearsSelectionOnViewWillAppear = splitViewController?.isCollapsed ?? false
    }
    
    // MARK: Table View Methods
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return classes.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return classes[section].count
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return classes[section].count > 0 ? 44 : 0
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let sem = semesters[section]
        return "\(sem.term) \(sem.year)"
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard let header = view as? UITableViewHeaderFooterView else { return }
        header.tintColor = UIColor.tableViewHeader
        header.textLabel?.font = UIFont.boldSystemFont(ofSize: 17)
        header.textLabel?.textColor = UIColor.unselected
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ClassCell", for: indexPath) as! ClassTableViewCell
        let classObj = self.classObj(at: indexPath)
        cell.classTitleLabel.text = classObj.name
        cell.classDateLabel.text = "\(classObj.semester!.term) \(classObj.semester!.year)"
        cell.ribbonColor = classObj.color
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if classObj(at: indexPath).isClassInProgress {
            performSegue(withIdentifier: .showDetail, sender: indexPath)
        } else {
            performSegue(withIdentifier: .showPreviousDetail, sender: indexPath)
        }
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let editAction = UITableViewRowAction(style: .normal, title: "Edit", handler: { [weak self] _, path in
            self?.performSegue(withIdentifier: .addEditClass, sender: path)
        })
        
        editAction.backgroundColor = UIColor.info
        
        
        let deleteAction = UITableViewRowAction(style: .destructive, title: "Delete", handler: { [weak self] _, path in
            self?.handleDelete(at: path)
        })
        
        deleteAction.backgroundColor = UIColor.warning
        
        return [editAction, deleteAction]
    }
    
    // MARK: Helper Methods
    
    /// This generates all of the possible Semester combinations, this array will be the sections for the table view
    private func generateSemesters() -> [Semester] {
        let terms: [String]
        
        /// Load semesters from user defaults, if for some reason this isnt saved, fall back to default semesters
        if let t = UserDefaults.standard.stringArray(forKey: UserDefaultKeys.terms.rawValue) {
            terms = t
        } else {
            print("WARNING: Something went wrong when loading semesters from UserDefaults, loading default set instead.")
            terms = ["Spring", "Summer", "Fall", "Winter"]
        }
        
        let years = UISemesterPickerView.createArrayOfYears()
        var results = [Semester]()
        
        for year in years {
            for term in terms {
                results.append(Semester(withTerm: term, andYear: year))
            }
        }
        return results
    }
    
    /// Loads all the Class objects in Realm into the `classes` array, grouped by their semester and sorted by their date.
    private func loadClasses() {
        let realm = DatabaseManager.shared.realm
        let all = realm.objects(Class.self)
        // The rest of the arrays inside the `classes` array will be grouped by their semester
        semesters.forEach {
            let classes = all.filter("semester.term == %@ AND semester.year == %@", $0.term, $0.year)
            self.classes.append(classes)
        }
    }
    
    /// Creates realm notifications for each array of classes in the `classes` array
    private func registerNotifications(for results: Results<Class>, in section: Int) {
        let notification = results.addNotificationBlock { [weak self] (changes) in
            guard let tableView = self?.tableView else { return }
            switch changes {
            case .initial: tableView.reloadData()
            case .update(let results, let deletions, let insertions, let modifications):
                tableView.beginUpdates()
                tableView.insertRows(at: insertions.map { IndexPath(row: $0, section: section) }, with: .automatic)
                tableView.deleteRows(at: deletions.map { IndexPath(row: $0, section: section)}, with: .automatic)
                tableView.reloadRows(at: modifications.map { IndexPath(row: $0, section: section) }, with: .automatic)
                // If this section had no cells previously, reload the section as well
                if results.count - insertions.count == 0 {
                    tableView.reloadSections(IndexSet(integer: section), with: .automatic)
                }
                tableView.endUpdates()
                self?.reloadEmptyState()
            case .error(let error): fatalError("Error in Realm notification change.\n \(error)")
            }
        }
        notificationTokens.append(notification)
    }
    
    /// Returns a class object at a specified index path
    private func classObj(at path: IndexPath) -> Class {
        return classes[path.section][path.row]
    }
    
    /// Deletes a class from Realm
    private func deleteClass(_ classObj: Class) {
        // Remove object from Realm
        DatabaseManager.shared.deleteObjects(classObj.rubrics)
        DatabaseManager.shared.deleteObjects(classObj.assignments)
        DatabaseManager.shared.deleteObjects([classObj.semester!, classObj.grade!, classObj])
    }
    
    /// Handles deleting a cell and class object from the table view
    private func handleDelete(at path: IndexPath) {
        let classToDel = classObj(at: path)
        // Create a copy in case the user undoes the deletion
        let copy = classToDel.copy() as! Class
        
        // Set the associated rubric for the assignment to the exact same rubric in the rubrics array
        for assignment in copy.assignments {
            var sameRubric: Rubric?
            for rubric in copy.rubrics {
                if rubric == assignment.associatedRubric {
                    sameRubric = rubric
                    break
                }
            }
            
            assignment.associatedRubric = sameRubric
        }
    
        // Figure out whether we need to update the state of the detail controller or not
        // If yes then remove the detail controllers classObj, which will cause the view to configure and show correct message
        if classToDel.isClassInProgress {
            // In progress class
            let navController = (self.splitViewController?.viewControllers.last as? UINavigationController)
            let detailController = navController?.childViewControllers.first as? ClassDetailTableViewController
            if  detailController?.classObj == classToDel {
                detailController?.classObj = nil
                detailController?.updateUIForClassChanges()
            }
        } else {
            // Previous class, different process, just hide all the views and move on
            let navController = (self.splitViewController?.viewControllers.last as? UINavigationController)
            let prevDetailController = navController?.childViewControllers.first as? PreviousClassDetailViewController
            prevDetailController?.hideViews()
        }
        
        // Delete from Realm
        deleteClass(classToDel)
    
        reloadEmptyState()
        
        // Present snack bar to allow undo
        let snack = LPSnackbar(title: "Class deleted.", buttonTitle: "UNDO", displayDuration: 3.0)
        snack.viewToDisplayIn = self.view
        snack.bottomSpacing = (tabBarController?.tabBar.frame.height ?? 0) + 12
        
        snack.show() { [weak self] undone in
            guard undone else { return }
            DatabaseManager.shared.addObject(copy)
            self?.reloadEmptyState()
        }
    }
    
    // MARK: Deinit
    
    deinit {
        notificationTokens.forEach {
            $0.stop()
        }
    }
}

// MARK: Segues

extension ClassesTableViewController: Segueable {
    
    /// Conformance for Seguable protocol
    enum SegueIdentifier: String {
        case showDetail = "showDetail"
        case showPreviousDetail = "showPreviousDetail"
        case addEditClass = "addEditClass"
        case onboarding = "onboardingSegue"
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Do any preperations before performing segue
        switch segueIdentifier(forSegue: segue) {
            
        case .showDetail:
            guard let indexPath = sender as? IndexPath else { return }
            
            let classItem: Class = classObj(at: indexPath)
            
            let controller = (segue.destination as! UINavigationController).topViewController as! ClassDetailTableViewController
            controller.classObj = classItem
            controller.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem
            controller.navigationItem.leftItemsSupplementBackButton = true
            
        case .showPreviousDetail:
            guard let indexPath = sender as? IndexPath else { return }
            
            let classItem: Class = classObj(at: indexPath)
            
            let controller = (segue.destination as! UINavigationController).topViewController as! PreviousClassDetailViewController
            controller.title = "Previous Class"
            controller.className = classItem.name
            controller.gradeString = classItem.grade?.gradeLetter
            controller.classColor = classItem.color
            
        case .addEditClass:
            guard let controller = segue.destination as? AddEditClassViewController else { return }
            
            // If editing then set the appropriate obj into the view controller, when user clicks edit
            // the sender provided will be an index path, using this we can get the object at that path
            if let path = sender as? IndexPath {
                controller.classObj = classObj(at: path)
            }
            
            let screenSize = UIScreen.main.bounds.size
            
            if UIDevice.current.userInterfaceIdiom == .pad {
                controller.preferredContentSize = CGSize(width: screenSize.width / 2, height: screenSize.height / 2)
            } else {
                controller.preferredContentSize = CGSize(width: screenSize.width * 0.65, height: screenSize.height * 0.85)
            }
            
            // Collapse any edit actions for the tableview, so theyre not opened when returning
            self.tableView.isEditing = false
            
        case .onboarding:
            break
        }
    }
}

// MARK: UIEmptyState Data Source & Delegate

extension ClassesTableViewController: UIEmptyStateDataSource, UIEmptyStateDelegate {
    
    // Empty State Data Source
    
    func shouldShowEmptyStateView(forTableView tableView: UITableView) -> Bool {
        // If not items then empty, show empty state
        return DatabaseManager.shared.realm.objects(Class.self).count == 0
    }
    
    var emptyStateTitle: NSAttributedString {
        let attrs: [NSAttributedStringKey: Any] = [.foregroundColor: UIColor.mainText,
                                                   .font: UIFont.systemFont(ofSize: 20)]
        return NSAttributedString(string: "No Classes Added", attributes: attrs)
    }
    
    var emptyStateImage: UIImage? { return #imageLiteral(resourceName: "EmptyClassesIcon") }
    
    var emptyStateButtonTitle: NSAttributedString? {
        let attrs: [NSAttributedStringKey: Any] = [.foregroundColor: UIColor.accentGreen,
                                                   .font: UIFont.systemFont(ofSize: 18)]
        return NSAttributedString(string: "Add a class", attributes: attrs)
    }
    
    var emptyStateButtonImage: UIImage? { return #imageLiteral(resourceName: "ButtonBg") }
    
    var emptyStateButtonSize: CGSize? { return CGSize(width: 160, height: 45) }
    
    var emptyStateViewAnimatesEverytime: Bool { return false }
    
    // Empty State Delegate
    
    func emptyStateViewWillShow(view: UIView) {

    }
    
    func emptyStateViewWillHide(view: UIView) {

    }
    
    func emptyStatebuttonWasTapped(button: UIButton) {
        self.performSegue(withIdentifier: .addEditClass, sender: button)
    }
}


// MARK: Split View Delegation

extension ClassesTableViewController: UISplitViewControllerDelegate {
    func splitViewController(_ splitViewController: UISplitViewController,
                             collapseSecondary secondaryViewController:UIViewController,
                             onto primaryViewController:UIViewController) -> Bool {
        
        guard let detailNavController = secondaryViewController as? UINavigationController else { return true }
        if let detailController = detailNavController.topViewController as? ClassDetailTableViewController {
            // In progress class, only collapse if classObj is nil
            return detailController.classObj == nil
        } else if let prevDetailController = detailNavController.topViewController as? PreviousClassDetailViewController {
            // Previous class, only collapse if views are hidden, if `bgView` is hidden, safe to assume they all are
            return prevDetailController.bgView.isHidden
        }
        
        
        return false
    }
}
