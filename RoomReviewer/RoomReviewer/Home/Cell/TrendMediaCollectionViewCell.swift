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
    
    private let shadowView = UIView().then {
        $0.layer.shadowColor = UIColor.black.cgColor
        $0.layer.shadowOpacity = 0.25
        $0.layer.shadowOffset = CGSize(width: 0, height: 2)
        $0.layer.shadowRadius = 4
        $0.layer.cornerRadius = 12
        $0.backgroundColor = .clear
    }
    
    private let posterImageView = UIImageView().then {
        $0.layer.cornerRadius = 12
        $0.clipsToBounds = true
        $0.contentMode = .scaleAspectFill
        $0.layer.borderWidth = 0.3
        $0.layer.borderColor = AppColor.appWhite.withAlphaComponent(0.3).cgColor
    }
    
    private let titleLabel = UILabel().then {
        $0.font = AppFont.semiboldSubTitle
        $0.numberOfLines = 0
        $0.textAlignment = .center
    }
    
    private let activityIndicator = UIActivityIndicatorView(style: .medium)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        configureHierarchy()
        configureLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureHierarchy() {
        contentView.addSubview(shadowView)
        contentView.addSubview(posterImageView)
        contentView.addSubview(activityIndicator)
        contentView.addSubview(titleLabel)
    }
    
    private func configureLayout() {
        shadowView.snp.makeConstraints {
            $0.top.horizontalEdges.equalToSuperview()
            $0.height.equalTo(shadowView.snp.width).multipliedBy(1.5)
        }

        posterImageView.snp.makeConstraints {
            $0.edges.equalTo(shadowView)
        }
        
        activityIndicator.snp.makeConstraints {
            $0.center.equalTo(posterImageView)
        }
        
        titleLabel.snp.makeConstraints {
            $0.top.equalTo(shadowView.snp.bottom).offset(5)
            $0.horizontalEdges.equalToSuperview()
            $0.bottom.equalToSuperview().inset(5)
        }
    }
    
    func bind(reactor: TrendMediaCollectionViewCellReactor) {
        reactor.state.map({ $0.isLoading })
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .bind(to: activityIndicator.rx.isAnimating)
            .disposed(by: disposeBag)
        
        reactor.state.map { $0.mediaName }
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: nil)
            .drive(titleLabel.rx.text)
            .disposed(by: disposeBag)
        
        reactor.state.map { $0.imageData }
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: nil)
            .drive(with: self) { owner, image in
                if let image = image {
                    if image == AppImage.emptyPosterImage {
                        owner.posterImageView.contentMode = .scaleAspectFit
                        owner.posterImageView.backgroundColor = AppColor.appLightGray
                        owner.posterImageView.tintColor = AppColor.appWhite
                    }
                    owner.posterImageView.image = image
                } else {
                    owner.posterImageView.backgroundColor = AppColor.appDarkGray
                }
            }
            .disposed(by: disposeBag)
        
        reactor.state.map { $0.imageData }
            .distinctUntilChanged()
            .filter { $0 == nil }
            .map { _ in
                TrendMediaCollectionViewCellReactor.Action.loadImage
            }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
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
