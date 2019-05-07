using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class RenderEvent : MonoBehaviour
{
    public Renderer L;
    public Renderer R;
    public static bool IsLRender = false;
    public static bool IsRRender = false;

    public Camera cam;
    void OnWillRenderObject()
    {
        if (Camera.current == cam)
        {
            if (L)
            {
                L.enabled = IsLRender;
                if(  L.enabled)
                Debug.Log(L + "w:" + L.enabled);

            }
            if (R)
            {
                R.enabled = IsRRender;
                if(  R.enabled)

                Debug.Log(R + "w:" + R.enabled);
            }
        }
    }
}
