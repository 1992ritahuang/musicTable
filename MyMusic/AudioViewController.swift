import UIKit
//import MediaPlayer    //匯入媒體播放框架，含UI
import AVFoundation   //匯入聲音影像播放框架，與MediaPlayer擇一使用就好，不含UI


class AudioViewController: UIViewController, AVAudioPlayerDelegate
{
    //專輯封面圖片
    @IBOutlet weak var imgPhoto: UIImageView!
    //播放與暫停按鈕
    @IBOutlet weak var buttonPlayAndPause: UIButton!
    //音樂播放進度滑桿（顯示進度）
    @IBOutlet weak var slider: UISlider!
    //標示已播放時間
    @IBOutlet weak var labelPlayedTime: UILabel!
    //標示剩餘時間
    @IBOutlet weak var labelLeftTime: UILabel!
    
    //宣告計時器
    weak var timer:Timer!
    
    //宣告音樂播放器
    var audioPlayer:AVAudioPlayer!
    
    //紀錄上一頁的執行實體
    weak var myTableViewController:MyTableViewController!
    
    //MARK: - 自訂函式
    func  countPlayTime()
    {
        //播放秒數/60，取商數作為分，取餘數作為秒
        //標示已播放時間
        labelPlayedTime.text = String(format: "%02d:%02d", Int(audioPlayer.currentTime) / 60, Int(audioPlayer.currentTime) % 60)
        //標示剩餘時間
        labelLeftTime.text = String(format: "%02d:%02d", (Int(audioPlayer.duration) - Int(audioPlayer.currentTime)) / 60, (Int(audioPlayer.duration) - Int(audioPlayer.currentTime)) % 60)
    }
    
    
    
    //由通知中心呼叫的事件
    @objc func audioIntrrupted(_ notification:Notification)
    {
        guard audioPlayer != nil, let userInfo = notification.userInfo else
        {
            return
        }
        print("由通知中心過來的字典：\(userInfo)")
        //電話撥入時會傳來字典[AVAudioSessionInterruptionTypeKey:1], 電話掛掉會傳[AVAudioSessionInterruptionTypeKey:0]
        guard let userMessage = userInfo[AVAudioSessionInterruptionTypeKey] else
        {
            return
        }
        
        let type_tmp = userMessage as! UInt
        print("中斷狀態：\(type_tmp)")
        
        //方法一：使用數字直接攔截中斷情況
        /*
        switch type_tmp
        {
        case 0:
            print("音樂播放中斷情況解除")
            audioPlayer.play()
        case 1:
            print("音樂播放中斷")
            audioPlayer.pause()
        default:
            print("狀況未知")
        }
        */
        
        //方法二：初始化列舉型別的實體，再攔截中斷狀況
        let type = AVAudioSession.InterruptionType(rawValue: type_tmp)
        switch type {
        case .ended:    //原始值為0
            print("音樂播放中斷情況解除")
            audioPlayer.play()
        case .began:    //原始值為1
            print("音樂播放中斷")
            audioPlayer.pause()
        default:
            print("狀況未知")
        }
    }
    
    //MARK: - Target Action
    //播放與暫停按鈕
    @IBAction func buttonPlayAndPause(_ sender: UIButton)
    {
        //audioPlayer不等於nil且不在播放中
        if audioPlayer != nil && !audioPlayer.isPlaying
        {
            audioPlayer.play()
            //更換按鈕背景圖片
            sender.setBackgroundImage(UIImage(named: "pause.png"), for: .normal)
            
            //第一次進行播放，則初始化計時器timer
            if timer == nil
            {
                //block內的東西每秒都會重複執行一次
                timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { (timer) in
                    //將目前的進度顯示在滑桿上
                    self.slider.value = Float(self.audioPlayer.currentTime)
                    //標示已播放時間＆剩餘時間
                    self.countPlayTime()
                    print("timer執行中")
                })
                print("Timer的引用計數\(CFGetRetainCount(timer)-1)")
            }
            
        }
        else
        {
            //暫停播放
            audioPlayer.pause()
            //更換成播放圖示
            sender.setBackgroundImage(UIImage(named: "play.png"), for: .normal)
            
        }
    }
    
    //停止按鈕
    @IBAction func buttonStop(_ sender: UIButton!)  //給預先拆封的選擇值，方便下面呼叫可以傳入nil
    {
        //要先檢查，因為audioPlayer是預先拆封的選擇值，避免當機
        if audioPlayer != nil
        {
            //停止播放
            audioPlayer.stop()
            //要重頭開始播放要將時間戳記(秒數)歸零，stop方法沒有reset這個參數所以不會自動重頭播放
            audioPlayer.currentTime = 0
            //更換成播放圖示
            buttonPlayAndPause.setBackgroundImage(UIImage(named: "play.png"), for: .normal)
            //滑桿進度歸零
            slider.value = 0
            //更新播放進度與剩餘時間標示
            countPlayTime()
            //停止計時器
                if timer != nil
                {
                    //停止計時器，會釋放由timer本身所使用的強引用，會將回0(timer所指向的記憶體配置空間會立即被釋放)
                    print("Timer的引用計數\(CFGetRetainCount(timer)-1)")
                    timer.invalidate()
                    //print("timer.invalidate()已釋放記憶體，此行無法執行, Timer的引用計數\(CFGetRetainCount(timer)-1)")

                    //注意：fire方法無法讓計時器重新啟動
                    //timer = nil
                    print("計時器停止")
                }
        
        }
        
    }
    
    
    @IBAction func sliderValueChange(_ sender: UISlider)
    {
        if audioPlayer != nil
        {
            print("滑桿值:\(sender.value)")
            //當使用者滑動滑桿，依目前滑值變更聲音的目前播放時間（回寫currentTime）
            audioPlayer.currentTime = TimeInterval(sender.value)
            //時機不需此行
            //audioPlayer.play()
            //標示已播放和剩餘時間
            countPlayTime()
        }
    }
    
    
    
    
    //MARK: - View Lifecycle
    override func viewDidLoad()
    {
        super.viewDidLoad()
        buttonPlayAndPause.isEnabled = false  //音樂下載完成前不允許按下播放按鈕
        print("聲音檔案：\(myTableViewController.songList[myTableViewController.currentRow].previewUrl)")
        print("APP根目錄\(NSHomeDirectory())")
        
        //和通知中心註冊一個音訊播放中斷通知，事項寫在name（AVAudioSession.interruptionNotification）注意打法
        //#selector()要對應一個執行函式
        NotificationCenter.default.addObserver(self, selector: #selector(audioIntrrupted(_:)), name: AVAudioSession.interruptionNotification, object: nil)
        
        //個別捕捉錯誤，分開do區段
        do
        {
            //設定音樂串流的形式為播放(注意：此段必須配合音樂背景播放設定運作，參考25-1以實機測試為準)
            //AVAudioSession音樂串流物件，呼叫型別方法sharedInstance()
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback)
            
        }
        catch
        {
            print("音樂串流形式設定錯誤：\(error)")
            return  //直接離開
        }
                
        //從上一頁的當筆資料來取得試聽帶網址
        let musicURL = myTableViewController.songList[myTableViewController.currentRow].previewUrl
        //準備試聽帶的資料傳輸任務
        var dataTask = URLSession.shared.dataTask(with: musicURL) {
            (musicData, response, error)
            in
            if let mData = musicData
            {
                //---------將下載的資料存擋-----------
                let filePath = NSHomeDirectory() + "/Documents/savedMusic.m4a"
                let fileURL = URL(fileURLWithPath: filePath)
                try? mData.write(to: fileURL)
                //---------------------------------
                
                //以下載到的m4a資料來初始化音樂播放器
                self.audioPlayer = try? AVAudioPlayer(data: mData)
                if self.audioPlayer != nil
                {
                    //指派audioPlayer的代理人為本頁的類別實體
                    //只有音樂播放器知道播放完畢了，丟入實作過此協定的類別實體
                    self.audioPlayer.delegate = self
                    //以上確認音樂檔案都取得沒有錯誤後，準備播放音樂(duration會有值)，不需要在do-catch裡面（忽略回傳值）
                    self.audioPlayer.prepareToPlay()
                    
                    //會改動到介面的值需放在執行緒內
                    DispatchQueue.main.async {
                        //在滑桿上標示聲音的最大時間
                        self.slider.minimumValue = 0
                        self.slider.maximumValue = Float(self.audioPlayer.duration)
                        //將目前播放進度設定在滑桿的目前位置
                        self.slider.value = Float(self.audioPlayer.currentTime)
                        //執行標示已播放時間＆剩餘時間的方法
                        self.countPlayTime()
                        //完成資料下載後，將按鈕開啟使用
                        self.buttonPlayAndPause.isEnabled = true
                    }
                }
            }
        }
        //開始下載試聽帶
        dataTask.resume()
        
        //從上一頁的當筆資料來取得專輯封面的網址物件
        let artWorkURL = myTableViewController.songList[myTableViewController.currentRow].artworkUrl100
        //準備專輯封面的資料傳輸任務
        dataTask = URLSession.shared.dataTask(with: artWorkURL, completionHandler: {
            (imgData, response, error)
            in
            if let idata = imgData
            {
                DispatchQueue.main.async {
                    self.imgPhoto.image = UIImage(data: idata)
                }
                
            }
        })
        //開始下載專輯封面
        dataTask.resume()
    }
    
    //MARK: - AVAudioPlayerDelegate
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool)
    {
        print("音樂播完了")
        //方法一：播完就停，執行復原動作
        //buttonStop(nil)
        //方法二：循環播放
        player.play()
    }
    
    //為了避免使用者沒有按暫停救回上一頁，因此離開此頁時就要按一下停止按鈕
    override func viewWillDisappear(_ animated: Bool)
    {
        super.viewWillDisappear(animated)
        //按一下停止鈕
        buttonStop(nil)
    }

}

