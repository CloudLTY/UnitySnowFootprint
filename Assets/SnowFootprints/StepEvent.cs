using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class StepEvent : MonoBehaviour
{
  public void DoLStep()
  {
      RenderEvent.IsLRender = true;
  }
    public void DoRStep()
  {
      RenderEvent.IsRRender = true;
  }
}
