using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Es_Effect_BottleWithinLiquid : MonoBehaviour
{
    public float SwingSpeed = 9;
    public float FadeSpeed = 1;
    public float ForceScale = 1;
    private Material mMaterial_Bottle;
    private Vector3 mLastPos;
    private Vector3 mLastAngle;
    private Vector3 mForceDir;
    private Vector3 mAngleDir;
    
    private Vector3 mSumForceDir;
    private Vector3 mSumAngleDir;
    

    void Start()
    {
        mForceDir = new Vector3(0, 0, 0);
        mSumForceDir = new Vector3(0, 0, 0);
        mSumAngleDir = new Vector3(0, 0, 0);

        mLastPos = transform.position;
        mLastAngle = transform.rotation.eulerAngles;
        if(gameObject.GetComponent<Renderer>())
            mMaterial_Bottle = gameObject.GetComponent<Renderer>().material;
        else
            mMaterial_Bottle = null;
    }

    // Update is called once per frame
    void Update()
    {
        if(!mMaterial_Bottle)
            return;
        mForceDir = transform.position - mLastPos;
        mAngleDir = transform.rotation.eulerAngles - mLastAngle;
        mAngleDir *= 0.05f;
        mForceDir *= ForceScale;

        mSumForceDir = Vector3.Lerp(mSumForceDir, new Vector3(0, 0, 0), Time.deltaTime * FadeSpeed);
        mSumAngleDir = Vector3.Lerp(mSumAngleDir, new Vector3(0, 0, 0), Time.deltaTime * FadeSpeed);
        mSumAngleDir.y = 0;

        Vector3 swingForceDir = mSumForceDir * Mathf.Cos(SwingSpeed*Time.time) + mSumAngleDir * Mathf.Cos(SwingSpeed*Time.time);

        mMaterial_Bottle.SetVector("_ForceDir", swingForceDir);
        mMaterial_Bottle.SetVector("_WorldZeroPos", transform.position);
        
        mSumForceDir += Vector3.ClampMagnitude(mForceDir, mForceDir.magnitude*0.15f);
        Debug.Log(mSumForceDir);
        mSumAngleDir += Vector3.ClampMagnitude(mAngleDir, 0.006f);

        mLastPos = transform.position;
        mLastAngle = transform.rotation.eulerAngles;
    }
}
