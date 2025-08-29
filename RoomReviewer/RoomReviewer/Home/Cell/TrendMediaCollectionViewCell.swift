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

final class TrendMediaCollectionViewCell: UICollectionViewCell, View {
    static let cellID = "TrendMediaCollectionViewCell"
    var disposeBag = DisposeBag()
    let imageView = UIImageView()
    
    private let shadowView = UIView().then {
        $0.layer.shadowColor = UIColor.black.cgColor
        $0.layer.shadowOpacity = 0.25
        $0.layer.shadowOffset = CGSize(width: 0, height: 2)
        $0.layer.shadowRadius = 4
        $0.layer.cornerRadius = 12
        $0.backgroundColor = .clear
    }
    
    let posterImageView = UIImageView().then {
        $0.layer.cornerRadius = 12
        $0.clipsToBounds = true
        $0.contentMode = .scaleAspectFill
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        configureHierarchy()
        configureLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configureHierarchy() {
        contentView.addSubview(shadowView)
        contentView.addSubview(posterImageView)
    }
    
    func configureLayout() {
        shadowView.snp.makeConstraints {
            $0.top.horizontalEdges.equalToSuperview().inset(10)
            $0.height.equalTo(shadowView.snp.width).multipliedBy(1.5)
        }

        posterImageView.snp.makeConstraints {
            $0.edges.equalTo(shadowView)
        }
    }
    
    func bind(reactor: HomeReactor) {
        
    }
}

extension TrendMediaCollectionViewCell {
    
    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
        reactor = nil
        posterImageView.image = nil
    }
}
