import UIKit

class MyCell: UITableViewCell
{
    @IBOutlet weak var imgPhoto: UIImageView!
    @IBOutlet weak var lblTrackName: UILabel!
    @IBOutlet weak var lblCollectionName: UILabel!
    @IBOutlet weak var lblArtistName: UILabel!
    @IBOutlet weak var lblReleaseDate: UILabel!
    
    override func awakeFromNib()
    {
        super.awakeFromNib()
        //縮放模式，填滿裁切避免變形
        imgPhoto.contentMode = .scaleAspectFill
        //邊緣裁切
        imgPhoto.clipsToBounds = true
        
    
    
    }

    override func setSelected(_ selected: Bool, animated: Bool)
    {
        super.setSelected(selected, animated: animated)
    }

}
