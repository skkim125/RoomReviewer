//
//  SearchMediaCollectionViewCell.swift
//  RoomReviewer
//
//  Created by 김상규 on 7/12/25.
//

import UIKit
import RxSwift
import RxCocoa
import ReactorKit
import SnapKit
import Then
import ImageIO

final class SearchMediaCollectionViewCell: UICollectionViewCell, View {
    static let cellID = "SearchMediaCollectionViewCell"
    private var imageDownsampler: ImageDownsampling?
    var disposeBag = DisposeBag()
    
    private let shadowView = UIView().then {
        $0.layer.shadowColor = UIColor.black.cgColor
        $0.layer.shadowOpacity = 0.25
        $0.layer.shadowOffset = CGSize(width: 0, height: 2)
        $0.layer.shadowRadius = 4
        $0.layer.cornerRadius = 8
        $0.backgroundColor = .clear
    }
    private let posterImageView = UIImageView().then {
        $0.layer.cornerRadius = 8
        $0.clipsToBounds = true
        $0.contentMode = .scaleAspectFill
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
    
    func configureCell(reactor: SearchMediaCollectionViewCellReactor, imageDownsampler: ImageDownsampling) {
        self.reactor = reactor
        self.imageDownsampler = imageDownsampler
    }
}

extension SearchMediaCollectionViewCell {
    func bind(reactor: SearchMediaCollectionViewCellReactor) {
        reactor.state.map({ $0.isLoading })
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .bind(to: activityIndicator.rx.isAnimating)
            .disposed(by: disposeBag)

        reactor.state.compactMap { $0.imageData }
            .map { [weak self] data -> (Data, CGSize) in
                guard let self = self else { return (data, .zero) }
                var target = self.posterImageView.bounds.size
                if target == .zero {
                    let width = self.contentView.bounds.width
                    target = CGSize(width: width, height: width * 1.5)
                }
                return (data, target)
            }
            .observe(on: ConcurrentDispatchQueueScheduler(qos: .userInitiated))
            .map { data, target in
                self.imageDownsampler?.downsampledImage(data: data, size: target)
            }
            .observe(on: MainScheduler.instance)
            .bind(with: self) { owner, image in
                if let image = image {
                    owner.posterImageView.image = image
                } else {
                    owner.posterImageView.backgroundColor = .systemGray6
                }
            }
            .disposed(by: disposeBag)

        
        reactor.state.map { $0.imageData }
            .distinctUntilChanged()
            .filter { $0 == nil }
            .map { _ in
                SearchMediaCollectionViewCellReactor.Action.loadImage
            }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        reactor = nil
        posterImageView.image = nil
    }
    
    private func configureHierarchy() {
        contentView.addSubview(shadowView)
        shadowView.addSubview(posterImageView)
        contentView.addSubview(activityIndicator)
    }
    
    private func configureLayout() {
        shadowView.snp.makeConstraints {
            $0.top.horizontalEdges.equalToSuperview()
            $0.height.equalTo(shadowView.snp.width).multipliedBy(1.5)
        }

        posterImageView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        activityIndicator.snp.makeConstraints {
            $0.center.equalTo(posterImageView)
        }
    }
}
