CREATE TABLE IF NOT EXISTS evaluation_datasets (
    id VARCHAR(36) PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id INTEGER NOT NULL,
    name VARCHAR(255) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_eval_datasets_tenant ON evaluation_datasets(tenant_id);

CREATE TABLE IF NOT EXISTS evaluation_queries (
    id VARCHAR(36) PRIMARY KEY DEFAULT uuid_generate_v4(),
    dataset_id VARCHAR(36) NOT NULL,
    qid VARCHAR(255) NOT NULL,
    text TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_eval_queries_dataset ON evaluation_queries(dataset_id);
CREATE UNIQUE INDEX IF NOT EXISTS uq_eval_queries_dataset_qid ON evaluation_queries(dataset_id, qid);

CREATE TABLE IF NOT EXISTS evaluation_qrels (
    id VARCHAR(36) PRIMARY KEY DEFAULT uuid_generate_v4(),
    dataset_id VARCHAR(36) NOT NULL,
    qid VARCHAR(255) NOT NULL,
    pid VARCHAR(255) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_eval_qrels_dataset ON evaluation_qrels(dataset_id);
CREATE UNIQUE INDEX IF NOT EXISTS uq_eval_qrels_dataset_qid_pid ON evaluation_qrels(dataset_id, qid, pid);

