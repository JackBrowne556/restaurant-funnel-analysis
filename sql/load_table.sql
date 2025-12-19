-- 1) EVENTS TABLE (UNCLEANED RAW EVENTS)
-- CSV columns: session_id,user_id,event_type,item_id,timestamp,platform,device,area,order_value

CREATE TABLE events_table (
    session_id      VARCHAR(32)  NOT NULL,
    user_id         VARCHAR(16)  NOT NULL,
    event_type      VARCHAR(32)  NOT NULL,
    item_id         INT,
    "timestamp"     TEXT         NOT NULL,  -- keep as TEXT because of mixed/unstandardized formats
    platform        VARCHAR(32)  NOT NULL,
    device          VARCHAR(16),
    area            VARCHAR(32),
    order_value     NUMERIC(8,2)           -- allows values up to 999,999.99
);

-- (Optional but recommended later, after cleaning)
-- CREATE INDEX idx_events_session ON events_table(session_id);
-- CREATE INDEX idx_events_timestamp ON events_table("timestamp");


-- 2) ITEMS TABLE
-- CSV columns: item_id,category,name,price,is_popular,menu_type

CREATE TABLE items_table (
    item_id     INT           PRIMARY KEY,
    category    VARCHAR(64)   NOT NULL,
    name        VARCHAR(160)  NOT NULL,
    price       NUMERIC(6,2)  NOT NULL,
    is_popular  BOOLEAN       NOT NULL,
    menu_type   VARCHAR(16)   NOT NULL      -- 'Brunch', 'Lunch', 'Dinner'
);


-- 3) WEATHER TABLE
-- CSV columns: date,city,temperature_c,condition

CREATE TABLE weather_table (
    "date"         DATE         PRIMARY KEY,
    city           VARCHAR(64)  NOT NULL,
    temperature_c  NUMERIC(4,1) NOT NULL,
    "condition"    VARCHAR(32)  NOT NULL
);


-- 4) PLATFORM METRICS TABLE
-- CSV columns: platform,commission_rate,avg_delivery_fee

CREATE TABLE platform_metrics_table (
    platform          VARCHAR(32)   PRIMARY KEY,
    commission_rate   NUMERIC(4,3)  NOT NULL,  -- e.g. 0.300
    avg_delivery_fee  NUMERIC(6,2)  NOT NULL   -- e.g. 4.99
);
