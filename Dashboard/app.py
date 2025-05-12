from __future__ import annotations
import os, decimal
from datetime import datetime, timezone, timedelta
from typing import Any, Dict, List

import boto3, pandas as pd, streamlit as st
from dotenv import load_dotenv
from streamlit_autorefresh import st_autorefresh

load_dotenv()
AWS_REGION       = os.getenv("AWS_REGION", "us-east-1")
DYNAMODB_TABLE   = os.getenv("DYNAMODB_TABLE", "stockout_alerts")
REFRESH_INTERVAL = int(os.getenv("REFRESH_INTERVAL", "30"))

st.set_page_config(
    page_title="Refill-Radar | Inventory Dashboard",
    page_icon="📉",
    layout="wide",
    initial_sidebar_state="expanded",
)
st_autorefresh(interval=REFRESH_INTERVAL * 1000, key="auto_refresh")

def table():
    return boto3.resource("dynamodb", region_name=AWS_REGION).Table(DYNAMODB_TABLE)

def _to_py(v: Any) -> Any:
    if isinstance(v, decimal.Decimal):
        return int(v) if v % 1 == 0 else float(v)
    return v

def _parse_ts(raw: Any) -> datetime:
    """
    Convert either an epoch (int/float/str) or an ISO-8601 string to UTC datetime.
    """
    # try numeric first
    try:
        return datetime.fromtimestamp(float(raw), tz=timezone.utc)
    except (ValueError, TypeError):
        # fallback: ISO string
        return datetime.fromisoformat(str(raw)).replace(tzinfo=timezone.utc)

def fetch_alerts() -> pd.DataFrame:
    items: List[Dict[str, Any]] = []
    resp = table().scan()
    items.extend(resp.get("Items", []))
    while "LastEvaluatedKey" in resp:
        resp = table().scan(ExclusiveStartKey=resp["LastEvaluatedKey"])
        items.extend(resp.get("Items", []))

    records = []
    for i in items:
        try:
            records.append(
                dict(
                    alert_id=_to_py(i["alert_id"]),
                    product_id=_to_py(i.get("product_id", "")),
                    product_name=_to_py(i.get("product_name", "")),
                    warehouse=_to_py(i.get("warehouse", "")),
                    quantity=_to_py(i.get("quantity", 0)),
                    threshold=_to_py(i.get("threshold", 0)),
                    alert_time=_parse_ts(i["alert_time"]),
                )
            )
        except (KeyError, ValueError, TypeError):
            continue  # skip malformed row

    return pd.DataFrame(records)

def kpi(label: str, value: str):
    st.markdown(
        f"""
        <div style='padding:1rem;background:#1f2937;border-radius:0.75rem;
             box-shadow:0 2px 6px rgba(0,0,0,0.15);text-align:center;'>
          <div style='font-size:0.9rem;color:#9ca3af;'>{label}</div>
          <div style='font-size:2rem;font-weight:600;color:#f3f4f6;'>{value}</div>
        </div>
        """,
        unsafe_allow_html=True,
    )


data = fetch_alerts()
st.sidebar.header("Filters"); now = datetime.now(timezone.utc)


wins = {
    "Last hour": now - timedelta(hours=1),
    "Last 12h" : now - timedelta(hours=12),
    "Last 24h" : now - timedelta(days=1),
    "Last 7d"  : now - timedelta(days=7),
    "All"      : datetime.fromtimestamp(0, tz=timezone.utc),
}
from_ts = wins[ st.sidebar.selectbox("Time range", list(wins), index=2) ]
if not data.empty: data = data[data["alert_time"] >= from_ts]

# product & warehouse filters
prods = sorted(data["product_name"].dropna().unique()) if not data.empty else []
whs   = sorted(data["warehouse"].dropna().unique())    if not data.empty else []
sel_p = st.sidebar.multiselect("Product", prods, default=prods[:10])
sel_w = st.sidebar.multiselect("Warehouse", whs,  default=whs)
if sel_p: data = data[data["product_name"].isin(sel_p)]
if sel_w: data = data[data["warehouse"].isin(sel_w)]

# KPIs (handles missing columns)
sku_cnt  = data["product_id"].nunique() if "product_id" in data else 0
outs_cnt = len(data)
today_cnt = (
    len(data[data["alert_time"].dt.date == now.date()])
    if "alert_time" in data else 0
)
c1,c2,c3 = st.columns(3)
with c1: kpi("Tracked SKUs",      f"{sku_cnt:,}")
with c2: kpi("Active Stock-outs", f"{outs_cnt:,}")
with c3: kpi("Alerts Today",      f"{today_cnt:,}")
st.markdown("---")

# chart or message
if data.empty:
    st.info("No stock-out alerts for the selected filters.")
else:
    ts = data.set_index("alert_time").groupby(pd.Grouper(freq="1h"))["alert_id"].count()
    st.area_chart(ts, use_container_width=True)

# detailed table
with st.expander("View raw alerts table"):
    if data.empty: st.write("No data.")
    else:
        df = data.sort_values("alert_time", ascending=False)
        df["alert_time"] = df["alert_time"].dt.strftime("%Y-%m-%d %H:%M:%S")
        st.dataframe(df, use_container_width=True)

# manual refresh
if st.sidebar.button("🔄 Manual refresh"):
    st.rerun()
