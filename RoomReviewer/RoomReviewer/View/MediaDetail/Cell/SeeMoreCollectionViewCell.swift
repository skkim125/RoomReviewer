//
//  SeeMoreCollectionViewCell.swift
//  RoomReviewer
//
//  Created by 김상규 on 9/29/25.
//

import UIKit
import SnapKit
import Then

final class SeeMoreCollectionViewCell: UICollectionViewCell {
    static let cellID = "SeeMoreCollectionViewCell"
    
    private let titleLabel = UILabel().then {
        $0.text = "출연진 모두 보기"
        $0.font = AppFont.semiboldSubTitle
        $0.textColor = AppColor.appWhite
    }
    
    private let chevronImageView = UIImageView().then {
        $0.image = UIImage(systemName: "chevron.right")
        $0.tintColor = AppColor.appLightGray
        $0.contentMode = .scaleAspectFit
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.backgroundColor = AppColor.appDarkGray
        contentView.layer.cornerRadius = 8
        
        configureHierarchy()
        configureLayout()
    }
    
    func configureHierarchy() {
        contentView.addSubview(titleLabel)
        contentView.addSubview(chevronImageView)
    }
    
    func configureLayout() {
        titleLabel.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
        
        chevronImageView.snp.makeConstraints {
            $0.leading.equalTo(titleLabel.snp.trailing).offset(8)
            $0.centerY.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
