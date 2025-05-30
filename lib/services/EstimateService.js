const estimateTables = {
  granite: {
    estimateTable: "granite_estimates",
    detailTable: "granite_estimates_details",
  },
  woodwork: {
    estimateTable: "woodwork_estimates",
    detailTable: "woodwork_estimate_details",
  },
  charcoal: {
    estimateTable: "charcoal_estimates",
    detailTable: "charcoal_estimate_details",
  },
  quartz: {
    estimateTable: "quartz_slab_estimates",
    detailTable: "quartz_slab_estimate_details",
  },
  wallpaper: {
    estimateTable: "wallpaper_estimates",
    detailTable: "wallpaper_estimate_details",
  },
  weinscoating: {
    estimateTable: "weinscoating_estimates",
    detailTable: "weinscoating_estimate_details",
  },
  false_ceiling: {
    estimateTable: "false_ceiling_estimates",
    detailTable: "false_ceiling_estimate_details",
  },
};

module.exports = (db) => {
  // ✅ Get all estimates with details by customerId and estimateType
  const getEstimatesByCustomerId = async (customerId, estimateType) => {
    try {
      const tableInfo = estimateTables[estimateType];
      if (!tableInfo) throw new Error("Invalid estimate type");

      const [results] = await db.promise().query(
        `SELECT ge.*, ged.*
         FROM ${tableInfo.estimateTable} ge
         JOIN ${tableInfo.detailTable} ged ON ge.id = ged.estimateId
         WHERE ge.customerId = ?`,
        [customerId]
      );

      return results;
    } catch (error) {
      console.error(`❌ Error fetching estimates:`, error.message);
      throw error;
    }
  };

  // ✅ Get estimate details by estimateId and estimateType
  const getEstimatesByEstimateId = async (estimateId, estimateType) => {
    try {
      const tableInfo = estimateTables[estimateType];
      if (!tableInfo) throw new Error("Invalid estimate type");

      const [results] = await db.promise().query(
        `SELECT * FROM ${tableInfo.detailTable} WHERE estimateId = ?`,
        [estimateId]
      );

      return results;
    } catch (error) {
      console.error(`❌ Error fetching estimate details:`, error.message);
      throw error;
    }
  };

  // ✅ Fetch estimates by type and customerId
  const fetchEstimatesByType = async (customerId, estimateType) => {
    try {
      const tableInfo = estimateTables[estimateType];
      if (!tableInfo) throw new Error("Invalid estimate type");

      const [results] = await db.promise().query(
        `SELECT * FROM ${tableInfo.estimateTable} WHERE customerId = ?`,
        [customerId]
      );

      return results;
    } catch (error) {
      console.error(`❌ Error fetching estimates by type:`, error.message);
      throw error;
    }
  };

  // ✅ Get granite estimate details by estimateId
  const getEstimateDetailsById = async (estimateId) => {
    try {
      const [results] = await db.promise().query(
        `SELECT * FROM granite_estimates WHERE id = ?`,
        [estimateId]
      );

      if (results.length > 0) {
        return results[0];
      } else {
        throw new Error("Granite estimate not found");
      }
    } catch (error) {
      console.error(`❌ Error fetching granite estimate:`, error.message);
      throw error;
    }
  };

  return {
    getEstimatesByCustomerId,
    getEstimatesByEstimateId,
    fetchEstimatesByType,
    getEstimateDetailsById,
  };
};
