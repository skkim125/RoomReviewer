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
}

extension SearchMediaCollectionViewCell {
    func bind(reactor: SearchMediaCollectionViewCellReactor) {
        reactor.state.map({ $0.isLoading })
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .bind(to: activityIndicator.rx.isAnimating)
            .disposed(by: disposeBag)

        reactor.state.compactMap { $0.imageData }
            .observe(on: MainScheduler.instance)
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
                self.downsampledImage(data: data, size: target, scale: UIScreen.main.scale)
            }
            .observe(on: MainScheduler.instance)
            .bind(to: posterImageView.rx.image)
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
        disposeBag = DisposeBag()
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
    
    func downsampledImage(data: Data, size: CGSize, scale: CGFloat = UIScreen.main.scale) -> UIImage? {
        let maxDimensionInPixels = max(size.width, size.height) * scale

        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxDimensionInPixels
        ]

        return data.withUnsafeBytes { raw -> UIImage? in
            guard let base = raw.baseAddress, raw.count > 0 else { return nil }
            let cfData = CFDataCreate(kCFAllocatorDefault, base.assumingMemoryBound(to: UInt8.self), raw.count)!
            guard let src = CGImageSourceCreateWithData(cfData, nil),
                  let cgImg = CGImageSourceCreateThumbnailAtIndex(src, 0, options as CFDictionary) else { return nil }
            return UIImage(cgImage: cgImg)
        }
    }
}
