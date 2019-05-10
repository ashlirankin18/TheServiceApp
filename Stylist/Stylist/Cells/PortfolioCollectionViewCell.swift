//
//  PortfolioCollectionViewCell.swift
//  Stylist
//
//  Created by Oniel Rosario on 4/12/19.
//  Copyright © 2019 Ashli Rankin. All rights reserved.
//

import UIKit

class PortfolioCollectionViewCell: UICollectionViewCell {
    @IBOutlet var container: UICollectionViewCell!
    @IBOutlet weak var portfolioImage: UIImageView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    
    func commonInit() {
     
        Bundle.main.loadNibNamed("PortfolioCell", owner: self, options: nil)
       portfolioImage.frame = CGRect(x: 0, y: 0, width: frame.width/2, height: 300)
      portfolioImage.backgroundColor = .white
        addSubview(container)
      
    }

}
