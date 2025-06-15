//
//  HomeTVCollectionViewCell.swift
//  RoomReviewer
//
//  Created by 김상규 on 6/15/25.
//

import UIKit
import RxSwift
import RxCocoa
import ReactorKit
import SnapKit
import Then

final class HomeTVCollectionViewCell: UICollectionViewCell {
    static let cellID = "HomeTVCollectionViewCell"
    
    private let tvNameLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 14, weight: .bold)
        $0.textColor = .black
        $0.textAlignment = .center
        $0.numberOfLines = 0
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        configureHierarchy()
        configureLayout()
    }
    
    func configureCellUI(data tv: TV) {
        contentView.backgroundColor = .systemGray6
        contentView.layer.cornerRadius = 8
        contentView.clipsToBounds = true
        tvNameLabel.text = tv.originalName
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension HomeTVCollectionViewCell {
    private func configureHierarchy() {
        contentView.addSubview(tvNameLabel)
    }
    
    private func configureLayout() {
        
        tvNameLabel.snp.makeConstraints {
            $0.horizontalEdges.equalTo(contentView).inset(10)
            $0.centerY.equalTo(contentView)
        }
    }
}
