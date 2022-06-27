pragma solidity >=0.8.0;
pragma experimental ABIEncoderV2;
import "@openzeppelin/contracts/utils/Strings.sol";
contract SmartLocker
{
    string [] public Uploaded_Item;  //已上傳的物品
    int [] private ItemUse;     //是否使用中
    string public OwnerName;  //賣家
    address public OwnerAddress;  //賣家地址
    address [] public CurrentAuthorizedUser; //誰正在使用
    string [] private requestitem;  //要求物品
    address [] private requestaddress; //要求人
    mapping(string => uint) private Prices_ether; //價格對照表

    constructor(string memory ownerName) public
    {
        OwnerAddress = msg.sender;
        OwnerName = ownerName;
    }

    function UploadItems(string memory Upload_Item,uint Price_ether) public  //上傳物品和價格
    {
        if (OwnerAddress != msg.sender)  //檢查是否為Owner
        {
            revert("YOU ARE NOT A OWNER !");
        }
        if(Uploaded_Item.length>=1){ //檢查是否上傳相同物品
            for(uint i=0; i < Uploaded_Item.length; i++){
                if(keccak256(bytes(Upload_Item)) == keccak256(bytes(Uploaded_Item[i])))
                    revert("Please dont upload samething !");
            }
        }
        Uploaded_Item.push(Upload_Item);  //紀錄已上傳物品
        Prices_ether[Upload_Item] = Price_ether; //紀錄價格
        ItemUse.push(0);  
        CurrentAuthorizedUser.push(msg.sender); 
    }

    function AcceptItemRequest() public  //接受租借請求
    {
        if (OwnerAddress != msg.sender) //檢查是否為OWNER
        {
            revert("you are not a owner");
        }
        for(uint i=0;i<requestitem.length;i++){ //遍歷所有請求，更改目前使用者以及使用狀態
            for(uint j=0;j<Uploaded_Item.length;j++){
                if(keccak256(bytes(requestitem[i])) == keccak256(bytes(Uploaded_Item[j]))){
                   CurrentAuthorizedUser[j]=requestaddress[i];
                    ItemUse[j]=1; 
                }
            }
        }
        delete requestitem; //清空請求
        delete requestaddress;
    }

    function RejectItemRequest() public  //拒絕租借請求
    {
        if (OwnerAddress != msg.sender) //檢查是否為OWNER
        {
            revert("you are not a owner");
        }
        for(uint i=0;i<requestitem.length;i++){   //遍歷請求，更改狀態
            for(uint j=0;j<Uploaded_Item.length;j++){
                if(keccak256(bytes(requestitem[i])) == keccak256(bytes(Uploaded_Item[j]))){
                    ItemUse[j]=0;
                }
            }
        }
        delete requestitem; //清空請求
        delete requestaddress;
        
    }

    function RequestItemAccess(string memory Item_Name) public payable //要求物品使用權
    {   
        
        if (OwnerAddress == msg.sender) //檢查是否為CUSTOMER
        {
            revert("you are not a customer");
        }
        uint i;
        for(i=0; i < Uploaded_Item.length; i++){  //檢查是否已擁有或已被別人使用或找不到
            if(keccak256(bytes(Item_Name)) == keccak256(bytes(Uploaded_Item[i])) && ItemUse[i]==0)break;
            if(i==Uploaded_Item.length-1)revert("Item not found or being used by other people or you already have!");
        }
        if(msg.value!=(Prices_ether[Item_Name]*1 ether))  //檢查金額是否符合該物品的價格
            {revert("Please pay the correct amount ether !"); }
        address payable payable_addr = payable(OwnerAddress); 
        payable_addr.transfer(msg.value); //轉帳給OWNER
        requestitem.push(Item_Name);  //新增請求
        requestaddress.push(msg.sender); 
        ItemUse[i]=2;
    }
    
    function TakeBackRightToUse(string memory Item) public  //拿回使用權
    {
        if (OwnerAddress != msg.sender) //檢查是否為OWNER
        {
            revert("you are not a owner");
        }
        uint i;
        for(i= 0; i < Uploaded_Item.length; i++){  //檢查物品存在
            if(keccak256(bytes(Item)) == keccak256(bytes(Uploaded_Item[i])))break;
            if(i==Uploaded_Item.length-1)revert("Item not found");
        }
        ItemUse[i]=0; 
        CurrentAuthorizedUser[i] = msg.sender;
    }
    function TakeBackAllRight() public  //拿回所有使用權
    {
        if (OwnerAddress != msg.sender) //檢查是否為OWNER
        {
            revert("you are not a owner");
        }
        for(uint i= 0; i < Uploaded_Item.length; i++){ //更改狀態和使用者
            ItemUse[i]=0;
            CurrentAuthorizedUser[i] = msg.sender;
        }
    }

    function Status(string memory item) public view returns(string memory) //物品狀態
    {   uint i;   
        for(i= 0; i < Uploaded_Item.length; i++){  //檢查物品存在
            if(keccak256(bytes(item)) == keccak256(bytes(Uploaded_Item[i])))break;
            if(i== Uploaded_Item.length-1)return "Not Found";
        }
        if(ItemUse[i]==0)return "Available"; //可租借
        if(ItemUse[i]==1)return "Occupied";  //已被租借
        if(ItemUse[i]==2)return "Pending";  //處理中
    }

    function AvailableItem() public view returns(string [10] memory) //已取得使用權的物品
    {   string [10] memory s;
        for(uint i= 0; i < CurrentAuthorizedUser.length; i++){
            if(msg.sender==CurrentAuthorizedUser[i])s[i]=Uploaded_Item[i];
        }
        return s;
    }
 
    function SeeAllItem() public view returns(string [10] memory) //所有物品
    {   string [10] memory s;
        for(uint i= 0; i < Uploaded_Item.length; i++){
            s[i]=Uploaded_Item[i];
        }
        return s;
    }

    function ClearAllItems() public  //清空所有物品
    {   if (OwnerAddress != msg.sender)
        {
            revert("you are not a owner");
        }
        delete Uploaded_Item;
        delete ItemUse;
        delete CurrentAuthorizedUser;
    }

    function ReturnItem(string memory item) public  //歸還物品
    {   if (OwnerAddress == msg.sender) //檢查是否為CUSTOMER
        {
            revert("you are not a customer");
        }
        for(uint i= 0; i < Uploaded_Item.length; i++){  
            if(CurrentAuthorizedUser[i]==msg.sender && keccak256(bytes(item)) == keccak256(bytes(Uploaded_Item[i]))){
                ItemUse[i]=0;
                CurrentAuthorizedUser[i]=OwnerAddress;
                break;
            }
            if(i==Uploaded_Item.length-1)revert("Item not found or you dont have");
        }
    }

    function Price(string memory Item_Name) public view returns(string memory) //搜尋價格
    {   
        return string(abi.encodePacked(Item_Name," cost ",Strings.toString(Prices_ether[Item_Name])," ethers"));
        //使用物品名稱尋找價格
    }
    
}