import UIKit

class FillMemoryViewController: UIViewController {

    @IBOutlet weak var allocMemoryButton: UIButton?
    @IBOutlet weak var spinner: UIActivityIndicatorView?
    @IBOutlet weak var progressView: UIProgressView?
    @IBOutlet weak var targetAmountSlider: UISlider?
    @IBOutlet weak var targetAmountLabel: UILabel?
    @IBOutlet weak var currentAllocAmountLabel: UILabel?

    var viewModel: FillMemoryViewModel! {
        didSet {
            viewModel.addObserver { _ in
                DispatchQueue.main.async { [weak self] in
                    self?.updateUI()
                }
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        updateUI()
    }

    func updateUI() {
        targetAmountSlider?.minimumValue = Float(viewModel.minTargetAmountInBytes)
        targetAmountSlider?.maximumValue = Float(viewModel.maxTargetAmountInBytes)
        targetAmountSlider?.value = Float(viewModel.targetAmountInBytes)
        targetAmountLabel?.text = viewModel.targetAmountLabelText

        currentAllocAmountLabel?.text = viewModel.currentAllocAmountLabelText

        allocMemoryButton?.isEnabled = viewModel.allocMemoryButtonEnabled
        allocMemoryButton?.setTitle(viewModel.allocMemoryButtonTitle, for: .normal)

        if viewModel.spinnerAnimating {
            spinner?.startAnimating()
        } else {
            spinner?.stopAnimating()
        }
        progressView?.progress = viewModel.allocMemoryProgress
    }

    @IBAction func targetAmountSliderChanged(_ sender: UISlider) {
        viewModel?.targetAmountInBytes = Int64(sender.value)
    }

    @IBAction func resetTargetAmount(_ sender: UIButton) {
        viewModel?.resetTargetAmountToDefault()
    }

    @IBAction func fillMemory(_ sender: UIButton) {
        viewModel.fillOrFreeDummyMemory()
    }
}
