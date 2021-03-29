using UnityEngine;
using System.Collections;
 
public class Sj : MonoBehaviour {
    public GameObject player;           //前台拖入胶囊
    Vector3 rot = new Vector3(0, 0, 0);   //先定义一个Vectory3类型的变量rot（0,0,0）
   public float speed;           //这个是鼠标灵敏度
    void Start() {
 
    }
 
    void Update() {
        float MouseX = Input.GetAxis("Mouse X")*speed;       
        float MouseY = Input.GetAxis("Mouse Y")*speed;
        rot.x = rot.x - MouseY;
        rot.y = rot.y + MouseX;  
        rot.z = 0;   //锁定摄像头移动的角度z轴，防止左右倾斜
        transform.eulerAngles = rot;   //所有方向设定好后，摄像头的角度=rot
        player.transform.eulerAngles = new Vector3(0, rot.y, 0);  //角色角度只能通过MouseX改变大小，也就是锁定rot.y
    }
}