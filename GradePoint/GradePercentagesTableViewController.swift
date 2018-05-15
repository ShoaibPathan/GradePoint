//
//  GradePercentagesTableViewController.swift
//  GradePoint
//
//  Created by Luis Padron on 5/4/18.
//  Copyright © 2018 Luis Padron. All rights reserved.
//

import UIKit
import RealmSwift

class GradePercentagesTableViewController: UITableViewController {

    /// The rows which will contain any + or - fields
    private let plusRows = [0, 2, 3, 5, 6,  8, 9, 11]

    /// The GPA scale type, which tells the controller how many of the cells to display (plus or no plus rows)
    private lazy var scaleType: GPAScaleType = DatabaseManager.shared.realm.objects(GPAScale.self).first!.scaleType

    /// The realm notifcation token for listening to changes on the GPAScale
    private var notifToken: NotificationToken?

    /// The GradeRubric object which this table manages
    private let rubric: GradeRubric = DatabaseManager.shared.realm.objects(GradeRubric.self).first!

    /// The grade percentage views, 1 per cell that the table statically displays
    @IBOutlet var percentageViews: [UIGradePercentageView]!

    // The header view for the table, displays an info message to the user with a reset button in the middle
    @IBOutlet var headerView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // UI Setup
        if #available(iOS 11.0, *) {
            self.navigationItem.largeTitleDisplayMode = .never
        }

        // TableView customization
        self.tableView.tableFooterView = UIView(frame: CGRect.zero)
        self.tableView.separatorColor = ApplicationTheme.shared.tableViewSeperatorColor
        self.tableView.estimatedRowHeight = 60

        // Add save button
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save,
                                                                 target: self,
                                                                 action: #selector(self.onSaveTapped))

        // Update headerview style
        (self.headerView.subviews[0] as! UILabel).textColor = ApplicationTheme.shared.mainTextColor()
        (self.headerView.subviews[1] as! UIButton).setTitleColor(ApplicationTheme.shared.highlightColor, for: .normal)

        self.addScaleChangeListener()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Initialize all the grade percentage views
        self.updateFields()

        // Add header view
        self.tableView.tableHeaderView = self.headerView
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    override var shouldAutorotate: Bool {
        return false
    }

    // MARK: - Table view methods

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if scaleType == .nonPlusScale && plusRows.contains(indexPath.row) { return 0 }
        else { return 60 }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 13
    }

    // MARK: - Actions

    @objc private func onSaveTapped(button: UIBarButtonItem) {

    }

    @IBAction func resetButtonTapped(_ sender: UIButton) {
        let title = NSAttributedString(string: "Reset To Default")
        let msg = NSAttributedString(string: "Are you sure you want to reset to default? This cant be undone")
        let alert = UIBlurAlertController(size: CGSize(width: 300, height: 200), title: title, message: msg)

        let cancelButton = UIButton(type: .custom)
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.setTitleColor(.white, for: .normal)
        cancelButton.backgroundColor = .info

        alert.addButton(button: cancelButton, handler: nil)

        let resetButton = UIButton(type: .custom)
        resetButton.setTitle("Reset", for: .normal)
        resetButton.setTitleColor(.white, for: .normal)
        resetButton.backgroundColor = .warning

        alert.addButton(button: resetButton, handler: self.resetPercentages)

        alert.presentAlert(presentingViewController: self)
    }

    // MARK: - Heleprs

    private func updateFields() {
        // Disable the upperbound field of the A+ or A since the upperbound is anything greater than lowerbound
        switch scaleType {
        case .plusScale:
            percentageViews.first?.upperLowerMode = false
        case .nonPlusScale:
            percentageViews[1].upperLowerMode = false
        }

        var rangeIndex = 0
        for (index, view) in percentageViews.enumerated() {
            view.lowerBoundField.font = UIFont.systemFont(ofSize: 18)
            view.upperBoundField.font = UIFont.systemFont(ofSize: 18)
            view.lowerBoundField.tintColor = ApplicationTheme.shared.highlightColor
            view.upperBoundField.tintColor = ApplicationTheme.shared.highlightColor
            view.lowerBoundField.textColor = ApplicationTheme.shared.highlightColor
            view.upperBoundField.textColor = ApplicationTheme.shared.highlightColor

            // TODO: Load grade letter ranges from DB
            let attrs = [NSAttributedStringKey.foregroundColor: ApplicationTheme.shared.secondaryTextColor(),
                         NSAttributedStringKey.font: UIFont.systemFont(ofSize: 18)]

            if scaleType == .nonPlusScale && self.plusRows.contains(index) { continue }

            if rangeIndex == 0 {
                view.lowerBoundField.attributedPlaceholder = NSAttributedString(string: "\(self.rubric.percentage(for: rangeIndex, type: .lowerBound))% +", attributes: attrs)
            } else {
                view.lowerBoundField.attributedPlaceholder = NSAttributedString(string: "\(self.rubric.percentage(for: rangeIndex, type: .lowerBound))%", attributes: attrs)
            }

            view.upperBoundField.attributedPlaceholder = NSAttributedString(string: "\(self.rubric.percentage(for: rangeIndex, type: .upperBound))%", attributes: attrs)
            rangeIndex += 1
        }
    }

    private func addScaleChangeListener() {
        let realm = try! Realm()
        self.notifToken = realm.objects(GPAScale.self).observe({ _ in
            // TODO: Add logic for default scale with plus and non-plus
            self.tableView.reloadData()
        })
    }

    private func resetPercentages() {
        let type = DatabaseManager.shared.realm.objects(GPAScale.self).first!.scaleType
        GradeRubric.createRubric(ofType: type)
        DispatchQueue.main.async {
            self.tableView.reloadData()
            for view in self.percentageViews {
                view.lowerBoundField.text = nil
                view.upperBoundField.text = nil
            }
        }
    }

    deinit {
        self.notifToken?.invalidate()
    }
}
