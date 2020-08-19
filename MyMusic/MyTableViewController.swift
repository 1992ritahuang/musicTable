import UIKit

//參考教學
//https://medium.com/彼得潘的-swift-ios-app-開發問題解答集/利用-swift-4-的-jsondecoder-和-codable-解析-json-和生成自訂型別資料-ee793622629e
//https://itunes.apple.com/search?term=田馥甄&media=music

//以自訂結構對應到json的內層資料（單首歌曲），每一筆key形成一個結構成員（只需取json資料中關心的key即可，不需要全部）
struct  Song:Codable    //引入Codable協定的目的是幫助json解碼器解碼
{
    var artistName:String
    var trackName:String
    var collectionName:String
    var previewUrl:URL   //Codable可辨識
    var artworkUrl100:URL
    var releaseDate:Date //Codable可辨識
}

//以Json外層資料來定義結構(即json解碼器操作的解碼架構)
struct SongResults:Codable    //引入Codable協定的目的是幫助json解碼器解碼
{
    var resultCount:Int
    var results:[Song] //型別是陣列，裝上面定義單首歌的內容
}


class MyTableViewController: UITableViewController {

    var songList = [Song]()   //宣告由json資料承接進來的離線資料集，下載下來的資料記錄在此陣列中
    var currentRow = 0        //紀錄目前點選的資料行
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        //https://itunes.apple.com/search?term=田馥甄&media=music
        //因為網址中有中文字要做百分比編碼, 會回傳選擇值
        if let urlStr = "https://itunes.apple.com/search?term=周興哲&media=music".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed), let url = URL(string: urlStr)
        {
            //設定取得itunes試聽帶的資料傳輸任務, 拿到預設的網路串流物件
            let dataTask = URLSession.shared.dataTask(with: url) {
                (jsonData, response, error)
                in
                //啟動json資料解碼器
                let jsonDecoder = JSONDecoder()
                //設定解碼器使用的日期解碼策略（yyyy-mm-dd）
                jsonDecoder.dateDecodingStrategy = .iso8601
                
                //讓json解碼器開始解碼，如果解碼成功以SongResults結構實體綁定到songResults
                if let jData = jsonData, let songResults = try? jsonDecoder.decode(SongResults.self, from: jData)
                {
                    self.songList = songResults.results
                    //第一時間會取得空陣列，網路存取完成後要做reload才會顯示出資料
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                    }
                }
                else
                {
                    print("沒有取得json資料，或json解碼錯誤")
                }
                print("取得的歌曲陣列：\(self.songList)")
                
                
            }
            //執行資料傳輸(注意：容易忘記)
            dataTask.resume()
        }
        
    }

    // MARK: - Table view data source
    //表格有幾段（外迴圈數量）
    override func numberOfSections(in tableView: UITableView) -> Int
    {
        return 1
    }
    //每一段表格有幾行資料（內迴圈數量）
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return songList.count
    }

    //準備每一個位置的儲存格
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MyCell", for: indexPath) as! MyCell //要精確轉型才可以拿到底下的屬性
        
        //從離線資料及取得當筆資料的結構實體
        let currentSong = songList[indexPath.row]
        
        cell.lblTrackName.text = currentSong.trackName
        cell.lblCollectionName.text = currentSong.collectionName
        cell.lblArtistName.text = currentSong.artistName
        
        //日期格式化
        let dateFormat = DateFormatter()                 //宣告格式化物件
        dateFormat.dateFormat = "yyyy/MM/dd HH:mm:ss"       //設定日期、時間格式化樣式
        dateFormat.locale = Locale(identifier: "zh_Hant_TW")  //設定地區：台灣
        dateFormat.timeZone = TimeZone(identifier: "Asia/Taipei")  //設定時區：台灣
        let dateStr:String = dateFormat.string(from: currentSong.releaseDate) //將專輯日期格式化
        //顯示格式化後的日期
        cell.lblReleaseDate.text = dateStr
        
        //專輯圖片-資料傳輸任務
        let dataTask = URLSession.shared.dataTask(with: currentSong.artworkUrl100) {
            (imgData, response, error)
            in
                       
            if let aImgData = imgData
            {
                DispatchQueue.main.async {
                    cell.imgPhoto.image = UIImage(data: aImgData)
                }
                
            }
            
        }
        //要執行才會顯示
        dataTask.resume()
        return cell
    }
    
    
    //MARK: - tableView Delegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        //紀錄目前點選位置
        currentRow = indexPath.row
    }


    
 
    // MARK: - Navigation
    //由換頁線換頁時
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        super.prepare(for: segue, sender: sender)
        //取得下一頁音樂播放器的實體
        let audioVC = segue.destination as! AudioViewController
        //並將下一頁的上一頁執行實體設定為自己
        audioVC.myTableViewController = self
        
    }


}
