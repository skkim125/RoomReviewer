
import UIKit
import SnapKit
import RxSwift
import Then

final class OfflineViewController: UIViewController {
    
    private var disposeBag = DisposeBag()
    var retryAction: (() -> Void)?
    
    private let iconImageView = UIImageView().then {
        $0.image = UIImage(systemName: "wifi.slash")
        $0.tintColor = AppColor.appGray
        $0.contentMode = .scaleAspectFit
    }
    
    private let messageLabel = UILabel().then {
        $0.text = "네트워크에 연결할 수 없습니다.\n연결 상태를 확인해주세요."
        $0.font = AppFont.semiboldSubTitle
        $0.textColor = AppColor.appLightGray
        $0.textAlignment = .center
        $0.numberOfLines = 0
    }
    
    private lazy var retryButton = CommonButton(title: "다시 시도", foregroundColor: AppColor.appWhite, backgroundColor: .systemRed)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColor.appBackgroundColor
        configureHierarchy()
        configureLayout()
        bind()
    }
    
    private func configureHierarchy() {
        view.addSubview(iconImageView)
        view.addSubview(messageLabel)
        view.addSubview(retryButton)
    }
    
    private func configureLayout() {
        iconImageView.snp.makeConstraints {
            $0.width.height.equalTo(80)
            $0.centerX.equalToSuperview()
            $0.bottom.equalTo(messageLabel.snp.top).offset(-5)
        }
        
        messageLabel.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.horizontalEdges.equalToSuperview().inset(40)
        }
        
        retryButton.snp.makeConstraints {
            $0.top.equalTo(messageLabel.snp.bottom).offset(20)
            $0.centerX.equalToSuperview()
            $0.width.equalTo(150)
        }
    }
    
    private func bind() {
        retryButton.rx.tap
            .subscribe(with: self) { owner, _ in
                owner.dismiss(animated: true) {
                    owner.retryAction?()
                }
            }
            .disposed(by: disposeBag)
    }
}
