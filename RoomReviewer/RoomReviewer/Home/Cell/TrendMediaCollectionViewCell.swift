//
//  TrendMediaCollectionViewCell.swift
//  RoomReviewer
//
//  Created by 김상규 on 8/29/25.
//

import UIKit
import RxSwift
import RxCocoa
import ReactorKit
import SnapKit
import Then

final class TrendMediaCollectionViewCell: UICollectionViewCell {
    static let cellID = "TrendMediaCollectionViewCell"
    let imageView = UIImageView()
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.addSubview(imageView)
        
        imageView.snp.makeConstraints { make in
            make.edges.equalTo(contentView.safeAreaLayoutGuide).inset(20)
        }
        
        imageView.layer.cornerRadius = 12
        imageView.clipsToBounds = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension TrendMediaCollectionViewCell {
    
    override func prepareForReuse() {
        super.prepareForReuse()
    }
}
