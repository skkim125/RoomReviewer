//
//  TierSectionHeaderView.swift
//  RoomReviewer
//
//  Created by 김상규 on 9/10/25.
//

import UIKit
import SnapKit
import Then

final class TierSectionHeaderView: UICollectionReusableView {
    static let reusableID = "TierSectionHeaderView"
    
    private let titleLabel = UILabel().then {
        $0.font = AppFont.boldTitle
        $0.textColor = AppColor.appWhite
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.cornerRadius = 12
        
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(10)
            make.centerY.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(title: String, color: UIColor) {
        titleLabel.text = title
        self.backgroundColor = color.withAlphaComponent(0.6)
    }
}
