select
    customer_id,
    cluster_id,
    segment_name as rfm_segment,
    model_version,
    scored_at
from {{ source('ds', 'customer_segment') }}
