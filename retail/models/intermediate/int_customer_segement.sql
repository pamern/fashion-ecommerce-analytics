select
    customer_id,
    cluster_id,
    segment_name,
    model_version,
    scored_at
from {{ source('ds', 'customer_segment') }}
