//
//  NetworkTableViewCell.swift
//  Chart Watch
//
//  Created by Eunmo Yang on 1/28/18.
//  Copyright © 2018 Eunmo Yang. All rights reserved.
//

import UIKit

class NetworkTableViewCell: UITableViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var item: ManagementItem? {
        didSet {
            titleLabel.text = item?.name
            
            if let status = item?.status {
                switch status {
                case .ongoing:
                    self.accessoryType = .none
                    activityIndicator.startAnimating()
                    break
                case .done:
                    self.accessoryType = .checkmark
                    activityIndicator.stopAnimating()
                    break
                default:
                    self.accessoryType = .none
                    activityIndicator.stopAnimating()
                    break
                }
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        activityIndicator.hidesWhenStopped = true
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    static var nib: UINib {
        return UINib(nibName: identifier, bundle: nil)
    }
    
    static var identifier: String {
        return String(describing: self)
    }
}
