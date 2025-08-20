//
//  CommonButton.swift
//  RoomReviewer
//
//  Created by 김상규 on 8/19/25.
//

import UIKit
import SnapKit

final class CommonButton: UIButton {
    init(title: String, foregroundColor: UIColor, backgroundColor: UIColor) {
        super.init(frame: .zero)
        var configuration = UIButton.Configuration.filled()
        let container = AttributeContainer(
            [.font: UIFont.systemFont(ofSize: 14, weight: .bold)]
        )
        configuration.attributedTitle = AttributedString(
            title,
            attributes: container
        )
        configuration.baseForegroundColor = foregroundColor
        configuration.baseBackgroundColor = backgroundColor
        
        self.configuration = configuration
        
        self.layer.cornerRadius = 12
        self.clipsToBounds = true
        
        snp.makeConstraints { make in
            make.height.equalTo(40)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
