//
//  ClassTableViewCell.swift
//  GradePoint
//
//  Created by Luis Padron on 10/12/16.
//  Copyright © 2016 Luis Padron. All rights reserved.
//

import UIKit

class ClassTableViewCell: UITableViewCell {
    
    // MARK: - Properties
    @IBOutlet weak var classRibbon: UIView!
    @IBOutlet weak var classTitleLabel: UILabel!
    @IBOutlet weak var classDateLabel: UILabel!
    
    /// The class associated with the cell
    var classObj: Class? {
        didSet {
            updateUI()
        }
    }
   
    // MARK: - Overrides
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        // Set the rounded corners and color for the ribbon
        classRibbon.layer.cornerRadius = classRibbon.bounds.size.width / 2
        classRibbon.layer.masksToBounds = false
        // Set the label text colors
        classTitleLabel.textColor = UIColor.mainText
        classDateLabel.textColor = UIColor.textMuted
        // Set background color for the cell
        self.backgroundColor = UIColor.darkBg
    }
    
    override func prepareForReuse() {
        // Remove all refrences to old class obj, since the cell will be reused and new class will be assigned
        self.classObj = nil
        classRibbon.backgroundColor = nil
        classTitleLabel.text = nil
        classDateLabel.text = nil
        super.prepareForReuse()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        updateForSelection(selected)
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        updateForSelection(highlighted)
    }
    
    // MARK: - Helper Methods
    
    func updateUI() {
        guard let classItem = classObj else {
            return
        }
        // Set the approritate ui types to their fields
        self.classTitleLabel.text = classItem.name
        self.classDateLabel.text = "\(classItem.semester!.term) \(classItem.semester!.year)"
        self.classRibbon.backgroundColor = NSKeyedUnarchiver.unarchiveObject(with: classItem.colorData) as? UIColor
    }
    
    func updateForSelection(_ selected: Bool) {
        guard let classItem = classObj else {
            return
        }
        // After selection occurs the cells "colorRibbon" dissapears since the UIView will become clear
        // reset the background color to the appropriate color
        self.classRibbon.backgroundColor = NSKeyedUnarchiver.unarchiveObject(with: classItem.colorData) as? UIColor
        // Set white color for date text, so it looks better
        if selected { self.classDateLabel.textColor = UIColor.lightText}
        else { self.classDateLabel.textColor = UIColor.textMuted }
    }
}
