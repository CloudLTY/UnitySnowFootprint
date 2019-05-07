using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

public class ResetRD : MonoBehaviour
{
    public Renderer L;
    public Renderer R;
    // Start is called before the first frame update

    void OnGUI()
    {

        if (RenderEvent.IsLRender)
        {
            RenderEvent.IsLRender = false;
        }

        if (RenderEvent.IsRRender)
        {
            RenderEvent.IsRRender = false;

        }
        L.enabled = R.enabled = true;
    }
}
