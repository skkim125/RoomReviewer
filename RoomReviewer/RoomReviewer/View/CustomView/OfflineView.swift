
import UIKit
import SnapKit
import RxSwift
import Then

final class OfflineView: UIView {
    
    private var disposeBag = DisposeBag()
    var retryAction: (() -> Void)?
    
    private let iconImageView = UIImageView().then {
        $0.image = UIImage(systemName: "wifi.slash")
        $0.tintColor = AppColor.appGray
        $0.contentMode = .scaleAspectFit
    }
    
    private let messageLabel = UILabel().then {
        $0.text = "오프라인 상태입니다.\n네트워크 연결 상태를 확인해주세요."
        $0.font = AppFont.semiboldCallout
        $0.textColor = AppColor.appLightGray
        $0.textAlignment = .center
        $0.numberOfLines = 0
    }
    
    private lazy var retryButton = CommonButton(title: "다시 연결하기", foregroundColor: AppColor.appWhite, backgroundColor: .appRed)
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
        
        configureHierarchy()
        configureLayout()
        self.backgroundColor = .clear
        bind()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureHierarchy() {
        self.addSubview(iconImageView)
        self.addSubview(messageLabel)
        self.addSubview(retryButton)
    }

    private func configureLayout() {
        iconImageView.snp.makeConstraints {
            $0.size.equalTo(50)
            $0.centerX.equalToSuperview()
            $0.bottom.equalTo(messageLabel.snp.top)
        }
        
        messageLabel.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.horizontalEdges.equalToSuperview().inset(40)
        }
        
        retryButton.snp.makeConstraints {
            $0.top.equalTo(messageLabel.snp.bottom).offset(10)
            $0.centerX.equalToSuperview()
            $0.width.equalTo(150)
        }
    }
    
    private func bind() {
        retryButton.rx.tap
            .subscribe(with: self) { owner, _ in
                owner.retryAction?()
            }
            .disposed(by: disposeBag)
    }
}
